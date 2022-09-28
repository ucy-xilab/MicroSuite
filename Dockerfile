# syntax=docker/dockerfile:1
FROM ubuntu:18.04
COPY ./MicroSuite /MicroSuite
CMD ["bash"]
