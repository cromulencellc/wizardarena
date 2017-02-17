FROM 32bit/ubuntu:14.04
ADD GEN_00000.xml /
ADD cb-replay /usr/bin/
ADD run-cb-replay /
RUN apt-get install -y python
ENTRYPOINT ["/run-cb-replay"]
CMD ["GEN_00000.xml"]
#RUN echo $env
#CMD ["bash"]
#ENTRYPOINT ["cb-replay"]
#CMD ["--host", CADET_PORT_1234_TCP_ADDR, "--port", CADET_PORT_1234_TCP_PORT, "--negotiate", "/GEN_00000.XML"]
