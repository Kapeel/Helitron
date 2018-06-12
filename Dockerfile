FROM      ubuntu:latest
MAINTAINER Kapeel Chougule

LABEL Description="Maize TE-annotation identification of Helitron using HelitronScanner"
RUN echo "tzdata tzdata/Areas select USA" > /tmp/preseed.txt; \
    echo "tzdata tzdata/Zones/USA select New York" >> /tmp/preseed.txt; \
    debconf-set-selections /tmp/preseed.txt && \
 #   rm /etc/timezone && \
 #   rm /etc/localtime && \
    apt-get update && \
    apt-get install -y tzdata
 
RUN apt-get install -y build-essential git cmake libxml2-dev zlib1g-dev libhdf5-dev wget curl apt-utils unzip libboost-all-dev default-jre default-jdk r-base libcurl4-openssl-dev libssl-dev 

### Install R packages
RUN echo 'source("https://bioconductor.org/biocLite.R")' > /tmp/packages.R \
# &&     echo 'biocLite("rtracklayer", dependencies=c("Depends", "Imports"))' >> /tmp/packages.R \
 &&	echo 'biocLite("rtracklayer")' >> /tmp/packages.R \ 
 &&     echo 'install.packages("stringr", dependencies = TRUE)' >> /tmp/packages.R \
 &&     echo 'install.packages("data.table", dependencies = TRUE)' >> /tmp/packages.R \
 &&     echo 'install.packages("plyr", dependencies = TRUE)' >> /tmp/packages.R \
 &&     Rscript /tmp/packages.R
 
### Install Blast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.26/ncbi-blast-2.2.26+-x64-linux.tar.gz \
 && tar -xvf ncbi-blast-2.2.26+-x64-linux.tar.gz \
 && mv ncbi-blast-2.2.26+ blast-2.2.26 \
 && cd blast-2.2.26/bin \
 && cp * /usr/bin \
 && cd ../..

### Install Silix
RUN wget ftp://pbil.univ-lyon1.fr/pub/logiciel/silix/silix-1.2.11.tar.gz \
 && tar -xvf silix-1.2.11.tar.gz \
 && cd silix-1.2.11 \
## && ./configure --enable-mpi --enable-verbose \
 && ./configure \
 && make \
 && make check \
 && make install \
 && cd ..

### Install genometools
RUN wget http://genometools.org/pub/genometools-1.5.10.tar.gz \
 && tar -xvf genometools-1.5.10.tar.gz \
 && cd genometools-1.5.10 \
 && make 64bit=yes cairo=no with-hmer=yes threads=yes \
 && cd ..

### Install HMMER
RUN wget http://eddylab.org/software/hmmer3/3.1b2/hmmer-3.1b2-linux-intel-x86_64.tar.gz \
 && tar -xvf hmmer-3.1b2-linux-intel-x86_64.tar.gz \
 && mv hmmer-3.1b2-linux-intel-x86_64 hmmer-3.1b2 \
 && cd hmmer-3.1b2/binaries \
 && cp * /usr/bin \
 && cd ../..

### Install vserach
RUN wget https://github.com/torognes/vsearch/releases/download/v2.8.0/vsearch-2.8.0-linux-x86_64.tar.gz \
 && tar -xvf vsearch-2.8.0-linux-x86_64.tar.gz \
 && mv vsearch-2.8.0-linux-x86_64 vsearch-2.8.0 \
 && cp vsearch-2.8.0/bin/vsearch /usr/bin 
 
### Install HelitronScanner
RUN wget http://sourceforge.net/projects/helitronscanner/files/HelitronScanner_V1.0.zip \
 && mkdir HelitronScanner \
 && mv HelitronScanner_V1.0.zip HelitronScanner \
 && cd HelitronScanner \
 && unzip HelitronScanner_V1.0.zip \
 && cd ..

##- Make TE repo

#RUN git clone -b helitron --single-branch https://github.com/Kapeel/maize_v4_TE_annotation.git
#RUN git clone https://github.com/mcstitzer/maize_v4_TE_annotation.git
RUN git clone https://github.com/Kapeel/Helitron.git

#WORKDIR /maize_v4_TE_annotation/helitron
RUN cd /Helitron/helitron_scripts

ENTRYPOINT ["sh", "/Helitron/helitron_scripts/run_helitron_scanner.sh"]
