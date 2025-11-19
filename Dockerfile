# docker buildx build -t rfdrake/tel .
# docker run -v /etc/telrc:/etc/telrc -v ~/.config/telrc:/telscript/.config/telrc -i rfdrake/tel hostname
FROM    perldocker/perl-tester

# Rather than git clone, we're going to build the currently checked out
# version.  This fixes some issues.. like not being able to test without
# committing, needing "--no-cache" to ensure rebuilds happen when the source
# is modified.  Stuff like that.
#ARG     BRANCH=master
#RUN git clone -b $BRANCH --depth 1 http://github.com/rfdrake/tel.git /tel
WORKDIR /tel

# pull in only the dist.ini file at first.
COPY dist.ini .

# Install author dependencies
RUN --mount=type=cache,target=/root/.perl-cpm   \
  (dzil authordeps --missing | cpm install --global -w 16 --no-test -)

# pull in the rest of the context (needed here because of AutoPreReqs and Git::GatherDir)
COPY . .

# Install regular dependencies
RUN --mount=type=cache,target=/root/.perl-cpm \
    (dzil listdeps --missing | cpm install -w 16 --global --no-test -)

RUN dzil test --all
RUN dzil install

RUN cpm install pp

# I would rather this run as a user, but I suspect there might be permissions
# problems with the telrc files.
RUN useradd telscript
USER telscript

ENTRYPOINT ["tel"]
CMD ["-h"]
