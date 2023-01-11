# MicroSuite
µSuite: A Benchmark Suite for Microservices

µSuite is a suite of OLDI services that are each composed of front-end, mid-tier, and leaf microservice tiers. μSuite includes four OLDI services that incorporate open-source software: a content-based high dimensional search for image similarity — HDSearch, a replication-based protocol router for scaling fault-tolerant key-value stores — Router, a service for performing set algebra on posting lists for document retrieval — Set Algebra, and a user-based item recommender system for predicting user ratings — Recommend.
µSuite was originally written to evaluate OS and network overheads faced by microservices. You can find more details about µSuite in our IISWC paper (http://akshithasriraman.eecs.umich.edu/pubs/IISWC2018-%CE%BCSuite-preprint.pdf).

This µSuite Fork has been amended by ALPS in order to achieve the following:
- Correct and confirm all the installation/compilations commands to run on Ubuntu Linux 18.04
- Provide instructions to compile and run docker and prepare a docker image with the complete µSuite for easier deployment
- Provide instructions and the configuration to run the applications on single node using docker-compose.yaml
- Provide intrusctions and the configuration to run the applications on multiple nodes using docker-compose-swarm.yml
- Provide instructions and source code to run the application on single node allowing the system to enter c6.

# License & Copyright
µSuite is free software; you can redistribute it and/or modify it under the terms of the BSD License as published by the Open Source Initiative, revised version.

µSuite was originally written by Akshitha Sriraman at the University of Michigan, and per the the University of Michigan policy, the copyright of this original code remains with the Trustees of the University of Michigan.

If you use this software in your work, we request that you cite the µSuite paper ("μSuite: A Benchmark Suite for Microservices", Akshitha Sriraman and Thomas F. Wenisch, IEEE International Symposium on Workload Characterization, September 2018), and that you send us a citation of your work.

# Installation
To install µSuite, please follow these steps (works on Ubuntu 18.04):

# (1) ** Setup docker, cli and compose **

```
curl -fsSL https://get.docker.com -o get-docker.sh
DRY_RUN=1 sh ./get-docker.sh
sudo sh get-docker.sh
sudo apt -y install docker-compose
```
## for saving docker login to be able to push images
```
sudo apt -y install gnupg2 pass 
```
## change the storage folder for more space to commit the image (in our case when we use Cloudlab)
```
sudo docker rm -f $(docker ps -aq); docker rmi -f $(docker images -q)
sudo systemctl stop docker
umount /var/lib/docker
sudo rm -rf /var/lib/docker
sudo mkdir /var/lib/docker
sudo mkdir /dev/mkdocker
sudo mount --rbind /dev/mkdocker /var/lib/docker
sudo systemctl start docker
```

# (2) ** Create a docker instance using our precompiled docker image **

```
mkdir microsuite
cd microsuite
git clone https://github.com/ucy-xilab/MicroSuite.git
cd MicroSuite
```
## Change to docker group
```
sudo newgrp docker
```
## Run docker compose
```
sudo docker compose up
```

At this point we need to open a new terminal and login on the docker instance to execute our benchmark
```
cd microsuite
su
docker-compose exec hdsearch sh
```

From this point on we can execute each benchmark based on the commands provided in section (4)

# (3) ** Run a multinode execution **

## All following commands should be run only on Node 0
## Close any docker-compose already running through the cloudlab profile
```
parallel-ssh -H "node0 node1 node2" -i "cd /microsuite/MicroSuite && sudo docker-compose down"
```
## Download dataset
```
cd /microsuite/MicroSuite && sudo wget https://akshithasriraman.eecs.umich.edu/dataset/HDSearch/image_feature_vectors.dat
```
## Create swarm on Node 0
```
sudo docker swarm init --advertise-addr 10.10.1.1
```
## Join other nodes on swarm
```
parallel-ssh -H "node1" -i "sudo docker swarm join --token `sudo docker swarm join-token worker -q` 10.10.1.1:2377"
parallel-ssh -H "node2" -i "sudo docker swarm join --token `sudo docker swarm join-token worker -q` 10.10.1.1:2377"

export NODE0=$(ssh node0 hostname)
export NODE1=$(ssh node1 hostname)
export NODE2=$(ssh node2 hostname)

cd /microsuite/MicroSuite
sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite
```
The provided docker-compose-swarm.yml file runs the HDSearch application. In order to run any other benchmark from the suite
you need to change this file and edit the commands for each service based on the ones provided in section (4).

In addition the following commands can be used to manage and monitor the progress of the nodes:
```
# Check services
sudo docker stack services microsuite

# Check logs
sudo docker service logs --raw microsuite_bucket
sudo docker service logs --raw microsuite_midtier

# Check a service, e.g. client
ssh node0
sudo docker exec -ti $(sudo docker ps --filter name=microsuite_bucket.1* -q) bash

ssh node1
sudo docker exec -ti $(sudo docker ps --filter name=microsuite_midtier.1* -q) bash

ssh node2
sudo docker exec -ti $(sudo docker ps --filter name=microsuite_client.1* -q) bash

# Close swarm
sudo docker stack rm microsuite
sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite
```

# (4) ** Run benchmarks **

## ** HDSearch **

### Dataset for HDSearch
```
wget https://akshithasriraman.eecs.umich.edu/dataset/HDSearch/image_feature_vectors.dat 
mv ./image_feature_vectors.dat /home

```
### Bucket Service Command
```
cd /MicroSuite/src/HDSearch/bucket_service/service
./bucket_server /home/image_feature_vectors.dat 0.0.0.0:50050 2 -1 0 1

```
### Mid Tier Service - sudo command not found...
```
cd /MicroSuite/src/HDSearch/mid_tier_service/service
touch bucket_servers_IP.txt
echo "0.0.0.0:50050" > bucket_servers_IP.txt
./mid_tier_server 1 13 1 1 bucket_servers_IP.txt /home/image_feature_vectors.dat 2 0.0.0.0:50051 1 4 4 0   

```
### Client 
```
cd /MicroSuite/src/HDSearch/load_generator
mkdir ./results
./load_generator_open_loop /home/image_feature_vectors.dat ./results/ 1 30 100 0.0.0.0:50051 dummy1 dummy2 dummy3

```

## ** Router **

### Dataset for Router
```
wget https://akshithasriraman.eecs.umich.edu/dataset/Router/twitter_requests_data_set.dat
wget https://akshithasriraman.eecs.umich.edu/dataset/Router/twitter_requests_data_set.txt
mv ./twitter_requests_data_set.dat /home
mv ./twitter_requests_data_set.txt /home

```
### Memchache server - confirm it runs
```
service memcached restart

```
### Lookup service command
```
cd /MicroSuite/src/Router/lookup_service/service
./lookup_server 0.0.0.0:50050 11211 -1 1

```
### Mid tier
```
cd /MicroSuite/src/Router/mid_tier_service/service/
touch lookup_servers_IP.txt
echo "0.0.0.0:50050" > lookup_servers_IP.txt
./mid_tier_server 1 lookup_servers_IP.txt 0.0.0.0:50051 1 1 1 1


```
### Client
```
cd /MicroSuite/src/Router/load_generator
mkdir ./results
./load_generator_closed_loop /home/twitter_requests_data_set.dat ./results 30 1000 0.0.0.0:50051 1 1
```

## ** SetAlgebra **

### Dataset for Set algebra
```
wget https://akshithasriraman.eecs.umich.edu/dataset/SetAlgebra/wordIDs_mapped_to_posting_lists.txt
mv ./wordIDs_mapped_to_posting_lists.txt /home

```
### Split dataset to multiple shrads, one per insersection intersection_server 
### (if only one intersection_server then use whole file). 
### In this example we split in 10 shrads (replace shards_num=10 below with number of shrads you would like)
```
rm /home/setalgebra_shrad*.txt;shrads_num=10;split -d --additional-suffix=.txt -l $(($(($(wc -l < /home/wordIDs_mapped_to_posting_lists.txt)+shrads_num-1))/shrads_num)) /home/wordIDs_mapped_to_posting_lists.txt /home/setalgebra_shrad

```
### Produce setalgebra_query_set.txt of N random lines (100 in this example) from dataset. 
### Client query set can be as large as we want
```
shuf -n 100 /home/wordIDs_mapped_to_posting_lists.txt > /home/setalgebra_query_set.txt

```
### Interesection server
### ./<intersection_server> \<IP address:Port Number> \<path to dataset> <num of cores: -1 if you want all cores on the machine> \<intersection server number> \<number of intersection servers in the system>
```
cd /MicroSuite/src/SetAlgebra/intersection_service/service/
./intersection_server 0.0.0.0:50050 /home/setalgebra_shrad00.txt 1 1 1

```
  
### Mid tier
### <./union_server> \<number of intersection servers> \<intersection server ips file> <ip:port number> \<union parallelism> \<union parallelism> \<union parallelism> \<dispatch parallelism> \<number of response threads>
```
cd /MicroSuite/src/SetAlgebra/union_service/service/
touch lookup_servers_IP.txt
echo "0.0.0.0:50050" > lookup_servers_IP.txt
./mid_tier_server 1 lookup_servers_IP.txt 0.0.0.0:50051 1 1 1
```

### Client
### ./<loadgen_union_client> \<queries file path> \<result file path> \<Time to run the program> \<QPS> \<IP to bind to>
```
cd /MicroSuite/src/SetAlgebra/load_generator
mkdir ./results
./load_generator_open_loop /home/setalgebra_query_set.txt ./results 30 1000 0.0.0.0:50051
```

## ** Recommend **

### Dataset for Recommend
```
wget https://www.mlpack.org/datasets/ml-20m/ratings-only.csv.gz
gunzip ratings-only.csv.gz
mv ./ratings-only.csv /home/user_to_movie_ratings.csv

```
### Split dataset to multiple shrads, one per cf server 
### (if only one cf_server then use whole file). 
### In this example we split in 100 shrads (replace shards_num=100 below with number of shrads you would like)
```
rm /home/user_to_movie_ratings_shard*.txt;shards_num=100;split -d --additional-suffix=.txt -l $(($(($(wc -l < /home/user_to_movie_ratings.csv)+shards_num-1))/shards_num)) /home/user_to_movie_ratings.csv /home/user_to_movie_ratings_shard

```
### Library to process the csv input file to create records of user,movie that have no rating
```
sudo apt-get install -y libtext-csv-perl

```
### Run the script to produce the combinations of users and movies that have no rating
```
perl missingmovies.pl ratings-only.csv
```
### move the resulted file to home
```
mv ./missingmovies.csv /home/missingmovies.csv

```
### Produce recommend_query_set.txt of N random lines (100 in this example) from the missingmovies.csv dataset. 
### Client query set can be as large as we want
```
sed 1d /home/missingmovies.csv | shuf -n 100 > /home/recommend_query_set.csv

```
### Server for shard 01
### ./<cf_server> <dataset file path> <IP address:Port Number> <Mode 1 - read dataset from text file OR Mode 2 - read dataset from binary file > <num of cores: -1 if you want all cores on the machine> <cf server number> <number of cf servers in the system>
```
cd /MicroSuite/src/Recommend/cf_service/service
./cf_server /home/user_to_movie_ratings_shard00.txt 0.0.0.0:50050 1 1 0 1

```
### Midtier
### <./recommender_server> <number of cf servers> <cf server ips file> <ip:port number> <recommender parallelism> <dispatch_parallelism> <number_of_response_threads>
```
cd /MicroSuite/src/Recommend/recommender_service/service/
touch lookup_servers_IP.txt
echo "0.0.0.0:50050" > lookup_servers_IP.txt
./mid_tier_server 1 lookup_servers_IP.txt 0.0.0.0:50051 1 1 1

```
### Load
### ./<loadgen_recommender_client> <queries file path> <result file path> <Time to run the program> <QPS> <IP to bind to>
```
cd /MicroSuite/src/Recommend/load_generator/
mkdir ./results
./load_generator_open_loop /home/recommend_query_set.csv results 30 1 0.0.0.0:50051
```

# (5) ** Commands used to compile the benchmarks and prepare the docker image **

## Install dependancies for microsuite
```
su
apt-get update
apt-get -y install build-essential autoconf libtool curl cmake git pkg-config
apt-get -y install libz-dev
apt-get -y install nano
apt-get -y install wget
apt-get -y install npm
npm install -g @bazel/bazelisk

```
## grpc
```
git clone -b v1.26.0 https://github.com/grpc/grpc
cd grpc
git submodule update --init
nano src/core/lib/debug/trace.cc
```
### CHANGE 
```
void TraceFlagList::Add(TraceFlag* flag) {
  flag->next_tracer_ = root_tracer_;
  root_tracer_ = flag;
}
```
### _CHANGE
```
```
### TO
```
void TraceFlagList::Add(TraceFlag* flag) {
  for (TraceFlag* t = root_tracer_; t != nullptr; t = t->next_tracer_) {
    if (t == flag) {
      return;
    }
  }
  flag->next_tracer_ = root_tracer_;
  root_tracer_ = flag;
```
### _TO
```
make
make install
cd ../

```
## protobuf
```
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.8.0/protobuf-cpp-3.8.0.tar.gz
tar -xzvf protobuf-cpp-3.8.0.tar.gz
cd protobuf-3.8.0/
./configure
make
make check
make install
ldconfig
cd ../

```
## OpenSSL and Intel's MKL
```
apt-get -y install openssl
apt-get -y install libssl-dev
apt-get -y install cpio
wget https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/12725/l_mkl_2018.2.199.tgz
tar xzvf l_mkl_2018.2.199.tgz
cd l_mkl_2018.2.199
./install.sh
cd ../

```
## FLAN
```
cd /MicroSuite/src/HDSearch/mid_tier_service/
mkdir build
cd build
cmake ..
make install
make

```
## MLPACK
```
apt-get -y install libmlpack-dev
```

## HDSearch benchmark
```
cd /MicroSuite/src/HDSearch/protoc_files
make

cd /MicroSuite/src/HDSearch/bucket_service/service/helper_files

nano server_helper.cc
#include <grpc/grpc.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>

nano client_helper.cc
#include <grpcpp/channel.h>
#include <grpcpp/client_context.h>
#include <grpc/status.h>

cd ../
make

cd ../../mid_tier_service/service/
apt-get install libboost-all-dev
apt-get install sudo -y
make

cd ../../load_generator/
make
```

## Router benchmark
```
cd /MicroSuite/src/Router/protoc_files
make clean
make

cd ../lookup_service/service
apt -y install libmemcached-dev
make

cd ../../mid_tier_service/service/
nano ../../lookup_service/service/helper_files/client_helper.cc
#include <grpcpp/channel.h>
make

cd ../../load_generator/
make

```
## mecachaded installation for this benchmark. Guide followed -> https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-memcached-on-ubuntu-18-04
```
apt install memcached
apt install libmemcached-tools
apt install systemd
service memcached restart

```
## Setalgebra benchmark
```
cd /MicroSuite/src/SetAlgebra/protoc_files
make clean
make

cd ../intersection_service/service/
make

cd ../../union_service/service
nano ../../intersection_service/service/helper_files/client_helper.cc
#include <grpcpp/channel.h>
make

cd ../../load_generator/
make

```
## Recommend benchmark
```
cd /MicroSuite/src/Recommend/protoc_files
make

cd /MicroSuite/src/Recommend/cf_service/service/
nano +280 cf_server.cc
cf_matrix = new CF(dataset, amf::NMFALSFactorizer(), 5, 5);    
//cf_matrix->Init();

nano helper_files/client_helper.cc
#include <grpcpp/channel.h>
make

cd ../../recommender_service/service/
make

cd ../../load_generator/
make
```
# (6) ** Commands used to compile and run the single node client and midtier**
### All benchmarks
```
To compile the single node client you must:
1) rename the *_singlenode source code under benchmarkname/load_generator/ and benchmarkname/load_generator/helper_files to its original name (remove singlenode from name).
2) make clean
3) make

To compile the single node mid_tier you must:
1) rename the *_singlenode source code under benchmarkname/mid_tier/ to its original name (remove singlenode from name)
2) make clean
3) make

To run single node experiments:
- Nothing changes for mid_tier and bucket services for all benchmarks
- Client accepts an additional parameter (last parameter). The core ID that the client will monitor for C6 entry/exit
```
