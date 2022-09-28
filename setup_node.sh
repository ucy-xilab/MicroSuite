#Setup docker, cli and compose    
    curl -fsSL https://get.docker.com -o get-docker.sh
    DRY_RUN=1 sh ./get-docker.sh
    sudo sh get-docker.sh
    sudo apt -y install docker-compose
    # for saving docker login to be able to push images
    sudo apt -y install gnupg2 pass 
    # change the storage folder for more space to commit the image
    sudo docker rm -f $(docker ps -aq); docker rmi -f $(docker images -q)
    sudo systemctl stop docker
    umount /var/lib/docker
    sudo rm -rf /var/lib/docker
    sudo mkdir /var/lib/docker
    sudo mkdir /dev/mkdocker
    sudo mount --rbind /dev/mkdocker /var/lib/docker
    sudo systemctl start docker

#Set a docker compose file    
    mkdir microsuite
    cd microsuite
    git clone https://github.com/ucy-xilab/MicroSuite.git
    cd MicroSuite
    
    # Change to docker group
    sudo newgrp docker
    
    # Run docker compose example
    sudo docker compose up
