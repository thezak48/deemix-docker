FROM node:alpine AS deemix

RUN apk add git jq && \
    git clone https://gitlab.com/RemixDev/deemix-gui.git && cd deemix-gui && \
    git submodule update --init --recursive && yarn install-all && \
    jq '.pkg.targets = ["node16-alpine-x64"]' ./server/package.json > tmp-json && \
    mv tmp-json /deemix-gui/server/package.json && \
    \
    # Patching deemix: see issue https://github.com/youegraillot/lidarr-on-steroids/issues/63
    sed -i 's/const channelData = await dz.gw.get_page(channelName)/let channelData; try { channelData = await dz.gw.get_page(channelName); } catch (error) { console.error(`Caught error ${error}`); return [];}/' ./server/src/routes/api/get/newReleases.ts && \
    yarn dist-server && mv /deemix-gui/dist/deemix-server /deemix-server


FROM hotio/base:alpine

LABEL maintainer="thezak48"
LABEL description="All credit goes to youegraillot with his Lidarr on Steroids repo. This is just a fork of it with deemix only."

ENV DEEMIX_SINGLE_USER=true
ENV AUTOCONFIG=true
ENV PUID=1000
ENV PGID=1000

# deemix
COPY --from=deemix /deemix-server /deemix-server
RUN chmod +x /deemix-server
VOLUME ["/config"]
EXPOSE 6595

COPY root /
RUN chmod +x /etc/services.d/*/run
VOLUME ["/config"]
EXPOSE 6595
