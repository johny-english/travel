# syntax=docker/dockerfile:experimental
ARG base_image
FROM $base_image
USER root

# Setup locale for fish's powerline fonts (https://hub.docker.com/r/jugal/docker-zsh/dockerfile)

ARG fish_install_script_args

RUN mkdir /fish_install_files
COPY ./ /fish_install_files

RUN --mount=type=cache,id=apt_common,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=apt_common,sharing=locked,target=/var/lib/apt \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y fish locales && \
    locale-gen "en_US.UTF-8" && \
    runuser -u $USER_NAME -- bash -c "mkdir -p ${HOME}/.config/fish && /fish_install_files/install_fish.sh --env /fish_install_files/$fish_install_script_args" && \
    rm -rf /fish_install_files

CMD ["/bin/fish"]
