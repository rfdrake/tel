# This doesn't really work for things like Pass/KeePass/Keyring.  It could
# probably be hacked together but I was only interested in getting it working
# as an experiment.

# docker build --no-cache -t rfdrake/tel .
# docker run -v /etc/telrc:/etc/telrc -v ~/.telrc2:/root/.telrc2 -i rfdrake/tel hostname

FROM    alpine:edge
RUN     apk -U add \
            perl \
            perl-dev \
            curl \
            wget \
            make \
            git \
            gcc \
            g++ \
            openssh-client

RUN curl -L https://cpanmin.us | perl - App::cpanminus
WORKDIR /tel
RUN git clone --depth 1 http://github.com/rfdrake/tel.git /tel
RUN cpanm --notest --installdeps .
RUN cpanm --notest Module::Install
RUN perl Makefile.PL && make && make install

ENTRYPOINT ["tel"]
CMD ["-h"]
