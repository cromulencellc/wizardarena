FROM 32bit/ubuntu:14.04
ADD cb-server /usr/bin/
ADD CADET_00002 /
EXPOSE 1234
ENTRYPOINT ["cb-server"]
CMD ["-p", "1234", "--negotiate", "--insecure", "-m", "1", "-d", ".", "CADET_00002"]
