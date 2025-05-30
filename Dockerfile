# docker buildx build -t rfdrake/tel .
# docker run -v /etc/telrc:/etc/telrc -v ~/.config/telrc:/telscript/.config/telrc -i rfdrake/tel hostname
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

# This command needs to run as root to install cpanm, so it happens before the
# USER command.
RUN curl -L https://cpanmin.us | perl - App::cpanminus
# Rather than git clone, we're going to build the currently checked out
# version.  This fixes some issues.. like not being able to test without
# committing, needing "--no-cache" to ensure rebuilds happen when the source
# is modified.  Stuff like that.
#ARG     BRANCH=master
#RUN git clone -b $BRANCH --depth 1 http://github.com/rfdrake/tel.git /tel
COPY . /tel
WORKDIR /tel

RUN cpanm --notest --installdeps . && cpanm --notest Module::Install
RUN perl Makefile.PL && make && make install

# I would rather this run as a user, but I suspect there might be permissions
# problems with the telrc files.
RUN adduser -D telscript
USER telscript

ENTRYPOINT ["tel"]
CMD ["-h"]
