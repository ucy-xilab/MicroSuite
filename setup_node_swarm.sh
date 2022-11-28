# All following commands should be run only on Node 0
# Close any docker-compose already running through the cloudlab profile
parallel-ssh -H "node0 node1 node2" -i "cd /microsuite/MicroSuite && sudo docker-compose down"
# Download dataset
cd /microsuite/MicroSuite && sudo wget https://akshithasriraman.eecs.umich.edu/dataset/HDSearch/image_feature_vectors.dat
# Create swarm on Node 0
sudo docker swarm init --advertise-addr 10.10.1.1
# Join other nodes on swarm
parallel-ssh -H "node1" -i "sudo docker swarm join --token `sudo docker swarm join-token worker -q` 10.10.1.1:2377"
parallel-ssh -H "node2" -i "sudo docker swarm join --token `sudo docker swarm join-token worker -q` 10.10.1.1:2377"

export NODE0=$(ssh node0 hostname)
export NODE1=$(ssh node1 hostname)
export NODE2=$(ssh node2 hostname)

cd /microsuite/MicroSuite
sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite
