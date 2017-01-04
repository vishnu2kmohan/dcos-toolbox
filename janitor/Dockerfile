FROM python:3.5-alpine

RUN pip install requests==2.9.1 click==6.3

COPY janitor.py /
RUN chmod +x /janitor.py

CMD ["/janitor.py"]
