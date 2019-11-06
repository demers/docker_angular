FROM ubuntu:18.04

MAINTAINER FND <fndemers@gmail.com>

ENV TERM=xterm\
    TZ=America/Toronto\
    DEBIAN_FRONTEND=noninteractive

ENV PROJECTNAME=ANGULAR

#ENV NVM_VERSION v0.33.11
ENV NVM_VERSION v0.35.0

ENV WORKDIRECTORY=/home/ubuntu

# Access SSH login
ENV USERNAME=ubuntu
ENV PASSWORD=ubuntu

RUN apt-get update

RUN apt-get install -y vim-nox curl git exuberant-ctags

# Install a basic SSH server
RUN apt install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN /usr/bin/ssh-keygen -A

# Install Java
RUN apt-get install -qy --no-install-recommends python-dev default-jdk

# Add user to the image
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${USERNAME} --gecos "User" ${USERNAME}
# Set password for the jenkins user (you may want to alter this).
RUN echo "$USERNAME:$PASSWORD" | chpasswd

RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen fr_CA.UTF-8
ENV TZ=America/Toronto
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
#RUN /usr/bin/timedatectl set-timezone $TZ
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/$TZ /etc/localtime


RUN apt install -y fish

RUN echo "export PS1=\"\\e[0;31m $PROJECTNAME\\e[m \$PS1\"" >> ${WORKDIRECTORY}/.bash_profile

# Ajout des droits sudoers
RUN apt-get install -y sudo
RUN echo "%ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install all you want here...


WORKDIR ${WORKDIRECTORY}

# Standard SSH port
EXPOSE 22

# Installation X11.
RUN apt install -y xauth vim-gtk

RUN apt-get install -y build-essential cmake python3-dev

RUN cd ${WORKDIRECTORY} \
    && git clone git://github.com/zaiste/vimified.git \
    && ln -sfn vimified/ ${WORKDIRECTORY}/.vim \
    && ln -sfn vimified/vimrc ${WORKDIRECTORY}/.vimrc \
    && cd vimified \
    && mkdir bundle \
    && mkdir -p tmp/backup tmp/swap tmp/undo \
    && git clone https://github.com/gmarik/vundle.git bundle/vundle \
    && echo "let g:vimified_packages = ['general', 'coding', 'fancy', 'indent', 'css', 'os', 'ruby', 'js', 'haskell', 'python', 'color']" > local.vimrc

COPY after.vimrc ${WORKDIRECTORY}/vimified/

COPY extra.vimrc ${WORKDIRECTORY}/vimified

# Générer les tags de ctags.
RUN echo "ctags -f ${WORKDIRECTORY}/mytags -R ${WORKDIRECTORY}" >> ${WORKDIRECTORY}/.bash_profile

#if ! [ -f /run/user/$UID/runonce_myscript ]; then
    #touch /run/user/$UID/runonce_myscript
    #/path/to/myscript
#fi

# Compiling YouCompleteMe only once...
RUN echo "if ! [ -f ~/.runonce_install ]; then" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "touch ~/.runonce_install" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "vim +BundleInstall +qall" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "cd ~/.vim/bundle/YouCompleteMe" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "./install.py --clang-completer" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "fi" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "cd ~/" >> ${WORKDIRECTORY}/.bash_profile

RUN apt -qy install gcc g++ make

RUN apt install -qy npm

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install NVM
#RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
#RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt install -y nodejs

# Install NODE
#RUN source /root/.nvm/nvm.sh; \
    #nvm install --lts

#ENV NODE_VERSION v8.10.0
#RUN source ~/.nvm/nvm.sh; \
    #nvm install $NODE_VERSION; \
    #nvm use --delete-prefix $NODE_VERSION;

RUN node --version

RUN npm install -g @angular/cli

# Port pour Angular
EXPOSE 4200

RUN ng --version

RUN cd ${WORKDIRECTORY} \
    && mkdir work \
&& chown -R $USERNAME:$PASSWORD work vimified .vim .vimrc .bash_profile


# Start SSHD server...
CMD ["/usr/sbin/sshd", "-D"]