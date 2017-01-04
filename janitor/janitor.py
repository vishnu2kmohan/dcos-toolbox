#!/usr/bin/env python

import getopt
import json
import logging
import os
import pprint
import re
import requests
import sys
import urllib

__verbose = False
__master_versions = {}

try:
    # Unknown certs are common/expected:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
except:
    print('Failed to disable requests.urllib3 warnings')

try:
    from urllib.parse import urljoin, urlparse
except ImportError:
    # Python 2
    from urlparse import urljoin, urlparse

try:
    import http.client as http_client
except ImportError:
    # Python 2
    import httplib as http_client


def request_url(method, url, req_headers, data={}, json={}):
    print('HTTP {}: {}'.format(method, url))
    try:
        return requests.request(method, url, headers=req_headers, data=data, json=json, verify=False)
    except requests.exceptions.Timeout:
        print('HTTP {} request timed out.'.format(method))
    except requests.exceptions.ConnectionError as err:
        print('Network error: {}'.format(err))
        parsed_url = urlparse(url)
        if parsed_url.scheme == 'http':
            # retry once with HTTPS instead of HTTP:
            print('Retrying request with HTTPS...')
            return request_url(method, re.sub(r'^http:', 'https:', url), req_headers, data=data, json=json)
    except requests.exceptions.HTTPError as err:
        print('Invalid HTTP response: {}'.format(err))
    return None


def extract_version_num(slaves_json):
    '''"0.28.0" => 28, "1.2.0" => 102'''
    if not slaves_json:
        print('Bad slaves response')
        return None
    # check the version advertised by the slaves
    for slave in slaves_json.get('slaves', []):
        version = slave.get('version', None)
        if version:
            break
    if not version:
        print('No version found in slaves list')
    version_parts = version.split('.')
    if len(version_parts) < 2:
        print('Bad version string: {}'.format(version))
        return None
    version_val = 100 * int(version_parts[0]) + int(version_parts[1])
    print('Mesos version: {} => {}'.format(version, version_val))


def get_state_json(master_url, req_headers):
    version_num = __master_versions.get(master_url, None)
    slaves_json = None
    if not version_num:
        # get version num from /slaves (and reuse response for volume info if version is >= 28)
        response = request_url('GET', urljoin(master_url, 'slaves'), req_headers)
        response.raise_for_status()
        version_num = __master_versions[master_url] = extract_version_num(response.json())
    if not version_num or version_num >= 28:
        # 0.28 and after only have the reservation data in /slaves
        if not slaves_json:
            response = request_url('GET', urljoin(master_url, 'slaves'), req_headers)
            response.raise_for_status()
            slaves_json = response.json()
        return slaves_json
    else:
        # 0.27 and before only have the reservation data in /state.json
        response = request_url('GET', urljoin(master_url, 'state.json'), req_headers)
        response.raise_for_status()
        return response.json()


def destroy_volumes(master_url, role, principal, req_headers={}):
    state = get_state_json(master_url, req_headers)
    if not state or not 'slaves' in state.keys():
        print('Missing data in state response: {}'.format(state))
        return False
    all_success = True
    for slave in state['slaves']:
        if not destroy_volume(slave, master_url, role, principal, req_headers):
            all_success = False
    return all_success


def destroy_volume(slave, master_url, role, principal, req_headers={}):
    volumes = []
    slaveId = slave['id']

    reserved_resources_full = slave.get('reserved_resources_full', None)
    if not reserved_resources_full:
        print('No reserved resources for any role on slave {}'.format(slaveId))
        return True

    reserved_resources = reserved_resources_full.get(role, None)
    if not reserved_resources:
        print('No reserved resources for role \'{}\' on slave {}. Known roles are: [{}]'.format(
            role, slaveId, ', '.join(reserved_resources_full.keys())))
        return True

    for reserved_resource in reserved_resources:
        name = reserved_resource.get('name', None)
        disk = reserved_resource.get('disk', None)

        if name == 'disk' and disk != None and 'persistence' in disk:
            volumes.append(reserved_resource)

    print('Found {} volume(s) for role \'{}\' on slave {}, deleting...'.format(
        len(volumes), role, slaveId))

    req_url = urljoin(master_url, 'destroy-volumes')
    data = {
        'slaveId': slaveId,
        'volumes': json.dumps(volumes)
    }
    if __verbose:
        print('Request URL: {}'.format(req_url))
        print('Request data: {}'.format(data))

    response = request_url('POST', req_url, req_headers, data=data)
    print('{} {}'.format(response.status_code, response.content))
    success = 200 <= response.status_code < 300
    if response.status_code == 409:
        print('''###\nIs a framework using these resources still installed?\n###''')
    return success


def delete_zk_node(exhibitor_url, znode, req_headers={}):
    """Delete Zookeeper node via Exhibitor (eg http://leader.mesos:8181/exhibitor/v1/...)"""
    znode_url = urljoin(exhibitor_url, 'exhibitor/v1/explorer/znode/{}'.format(znode))

    response = request_url('DELETE', znode_url, req_headers)
    if not response:
        return False

    if 200 <= response.status_code < 300:
        print('Successfully deleted znode \'{}\' (code={}), if znode existed.'.format(
            znode, response.status_code))
        return True
    else:
        print('ERROR: HTTP DELETE request returned code:', response.status_code)
        print('Response body:', response.text)
        return False


def unreserve_resources(master_url, role, principal, req_headers={}):
    state = get_state_json(master_url, req_headers)
    if not state or not 'slaves' in state.keys():
        return False
    all_success = True
    for slave in state['slaves']:
        if not unreserve_resource(slave, master_url, role, principal, req_headers):
            all_success = False
    return all_success


def unreserve_resource(slave, master_url, role, principal, req_headers={}):
    resources = []
    slaveId = slave['id']

    reserved_resources_full = slave.get('reserved_resources_full', None)
    if not reserved_resources_full:
        print('No reserved resources for any role on slave {}'.format(slaveId))
        return True

    reserved_resources = reserved_resources_full.get(role, None)
    if not reserved_resources:
        print('No reserved resources for role \'{}\' on slave {}. Known roles are: [{}]'.format(
            role, slaveId, ', '.join(reserved_resources_full.keys())))
        return True

    for reserved_resource in reserved_resources:
        resources.append(reserved_resource)

    print('Found {} resource(s) for role \'{}\' on slave {}, deleting...'.format(
        len(resources), role, slaveId))

    req_url = urljoin(master_url, 'unreserve')
    data = {
        'slaveId': slaveId,
        'resources': json.dumps(resources)
    }
    if __verbose:
        print('Request URL: {}'.format(req_url))
        print('Request data: {}'.format(data))

    response = request_url('POST', req_url, req_headers, data=data)
    print('{} {}'.format(response.status_code, response.content))
    return 200 <= response.status_code < 300


# URLs to use when running the script from inside a DCOS cluster:
MASTER_DEFAULT='http://leader.mesos:5050/master/'
EXHIBITOR_DEFAULT='http://leader.mesos:8181/'
MARATHON_DEFAULT='http://marathon.mesos:8080/v2/apps/'


def clean(role, principal, zk_path, master_url=MASTER_DEFAULT, exhibitor_url=EXHIBITOR_DEFAULT, req_headers={}):
    if not role and not principal and not zk_path:
        print('\nNothing to do!')
        return False
    if role and principal:
        print('\nDestroying volumes...')
        if not destroy_volumes(master_url, role, principal, req_headers):
            print('Deleting volumes failed, skipping other steps.')
            return False # resources will fail to delete if this fails
        print('\nUnreserving resources...')
        if not unreserve_resources(master_url, role, principal, req_headers):
            print('Deleting resources failed, skipping other steps.')
            return False # don't delete ZK if this fails, that'll likely leave things in inconsistent state
    if zk_path:
        print('\nDeleting zk node...')
        if not delete_zk_node(exhibitor_url, zk_path, req_headers):
            return False
    print('Cleanup completed successfully.')
    return True


def delete_self_if_marathon(marathon_url, req_headers={}):
    '''HACK: automatically delete ourselves from Marathon so that we don't execute in a loop'''
    marathon_task_id = os.environ.get('MARATHON_APP_ID', None)
    if not marathon_task_id:
        return

    print('Deleting self from Marathon to avoid run loop: {}'.format(marathon_task_id))
    marathon_app_url = urljoin(marathon_url, '{}'.format(marathon_task_id.strip('/')))
    response = request_url('DELETE', marathon_app_url, req_headers)
    if 200 <= response.status_code < 300:
        print('Successfully deleted self from marathon (code={}): {}'.format(
            response.status_code, marathon_task_id))
    else:
        print('ERROR: HTTP DELETE request returned code:', response.status_code)
        print('Response body:', response.text)


def print_help(argv):
    print('''{}
  -v/--verbose
  -r/--role=<framework-role>
  -p/--principal=<framework-principal>
  -z/--zk_path=<zk-path>
  [-m/--master_url={}]
  [-n/--marathon_url={}]
  [-e/--exhibitor_url={}]
  [--username=dcos_user]
  [--password=dcos_password]
  [-a/--auth_token=dcos_auth_tok]'''.format(argv[0], MASTER_DEFAULT, MARATHON_DEFAULT, EXHIBITOR_DEFAULT))


def main(argv):
    global __verbose
    role = ''
    principal = ''
    zk_path = ''
    master_url = MASTER_DEFAULT
    exhibitor_url = EXHIBITOR_DEFAULT
    marathon_url = MARATHON_DEFAULT
    username = ''
    password = ''
    auth_token = ''
    try:
        opts, args = getopt.getopt(argv[1:], 'hvm:e:n:r:p:z:a:', [
            'help', 'verbose',
            'master_url=', 'exhibitor_url=', 'marathon_url=',
            'role=', 'principal=', 'zk_path=',
            'username=', 'password=', 'auth_token='])
    except getopt.GetoptError as e:
        print('Failed to get options with exception ({}): '.format(e))
        print_help(argv)
        sys.exit(1)
    for opt, arg in opts:
        if opt in ['-h', '--help']:
            print_help(argv)
            sys.exit(2)
        elif opt in ['-v', '--verbose']:
            __verbose = True
        elif opt in ['-r', '--role']:
            role = arg
        elif opt in ['-p', '--principal']:
            principal = arg
        elif opt in ['-z', '--zk_path']:
            zk_path = arg
        elif opt in ['-m', '--master_url']:
            master_url = arg
        elif opt in ['-n', '--marathon_url']:
            marathon_url = arg
        elif opt in ['-e', '--exhibitor_url']:
            exhibitor_url = arg
        elif opt in ['--username']:
            username = arg
        elif opt in ['--password']:
            password = arg
        elif opt in ['-a', '--auth_token']:
            auth_token = arg

    if __verbose:
        http_client.HTTPConnection.debuglevel = 1
        logging.basicConfig()
        logging.getLogger().setLevel(logging.DEBUG)
        requests_log = logging.getLogger('requests.packages.urllib3')
        requests_log.setLevel(logging.DEBUG)
        requests_log.propagate = True

    if not marathon_url.endswith('/'):
        print('Marathon URL must end with trailing slash: {}'.format(marathon_url))
        sys.exit(3)
    if not master_url.endswith('/'):
        print('Master URL must end with trailing slash: {}'.format(master_url))
        delete_self_if_marathon(marathon_url) # fatal failure
        sys.exit(3)
    if not exhibitor_url.endswith('/'):
        print('Exhibitor URL must end with trailing slash: {}'.format(exhibitor_url))
        delete_self_if_marathon(marathon_url) # fatal failure
        sys.exit(3)

    print('Master: {} Exhibitor: {} Role: {} Principal: {} ZK Path: {}'.format(
        master_url, exhibitor_url, role, principal, zk_path))

    if username and password:
        # fetch auth token using provided username/pw

        # http://leader.mesos:5050/some/long/path => http://leader.mesos:5050
        master_host = '{}://{}'.format(urlparse(master_url).scheme, urlparse(master_url).hostname)

        req_url = urljoin(master_host, 'acs/api/v1/auth/login')
        response = request_url('POST', req_url, {}, json={ 'uid': username, 'password': password })
        if 200 <= response.status_code < 300:
            auth_token = response.json()['token']
        else:
            print('Token retrieval failed: {} {}'.format(response.status_code, response.content))
            delete_self_if_marathon(marathon_url) # fatal failure
            sys.exit(4)
    req_headers = {}
    if auth_token:
        # auth token was either fetched or supplied via '--auth_token'
        req_headers = {'Authorization': 'token={}'.format(auth_token)}

    if not clean(role, principal, zk_path, master_url, exhibitor_url, req_headers):
        print('') # add newline separation before help
        print_help(argv)
        if not __verbose:
            print('Retry command with "-v" to enable verbose logging.')
        # don't delete self from marathon: attempt to retry
        sys.exit(5)

    delete_self_if_marathon(marathon_url, req_headers) # success, don't try again!


if __name__ == '__main__':
    main(sys.argv)
