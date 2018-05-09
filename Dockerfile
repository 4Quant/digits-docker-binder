FROM kaixhin/digits:latest

# TensorBoard
EXPOSE 6006

# Create basic user
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

USER root
# install python3 and jupyter
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common curl graphviz

RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        python3.6 && \
    rm -rf /var/lib/apt/lists/*
RUN curl https://bootstrap.pypa.io/get-pip.py | python3.6
RUN pip3 install --upgrade setuptools pip
RUN pip3 install jupyter notebook
RUN pip3 install https://github.com/betatim/nbserverproxy/archive/master.zip

ENV HOME /root
# Copy repo into ${HOME}, make user own $HOME
COPY . ${HOME}

WORKDIR ${HOME}
RUN jupyter serverextension enable --py nbserverproxy
RUN pip3 install -e.
RUN jupyter serverextension enable --py nbdlstudioproxy
RUN jupyter nbextension     install --py nbdlstudioproxy
RUN jupyter nbextension     enable --py nbdlstudioproxy

RUN mv ${HOME}/4q.ico ${HOME}/digits/digits/static/images/nvidia.ico
# move the layout with fixed links
RUN mv ${HOME}/layout.html ${HOME}/digits/digits/templates/layout.html
WORKDIR ${HOME}/digits
RUN pip2 install opencv-python
RUN pip2 install tensorflow==1.2.1
RUN python setup.py install

# install two plugins
WORKDIR ${HOME}/digits_plugins/sunnybrook/
RUN python setup.py install
WORKDIR ${HOME}/digits_plugins/imageGradients/
RUN python setup.py install

WORKDIR ${HOME}
# get some test data to play with
RUN python -m digits.download_data cifar10 ~/cifar10
RUN chown -R ${NB_USER} ${HOME}

USER ${NB_USER}
WORKDIR ${HOME}
# download sunnybrook data
RUN mkdir ${HOME}/sunnybrook
WORKDIR ${HOME}/sunnybrook
RUN curl 'http://www.cardiacatlas.org/share/download.php?id=3&token=WgD8N1RrY2QvAL245wTPMCAeSAcRTjJG&download' -o dicoms.zip
RUN unzip dicoms.zip
RUN rm dicoms.zip
RUN curl 'http://www.cardiacatlas.org/share/download.php?id=2&token=IlxjOeV7ZviYLTqP627LmqqVHtyUuuK3&download' -o contours.zip
RUN unzip contours.zip
RUN rm contours.zip
WORKDIR ${HOME}
# setup environment
ENV DIGITS_JOBS_DIR=${HOME}/jobs
ENV DIGITS_LOGFILE_FILENAME=${HOME}/digits.log
ENV PYTHONPATH=/usr/local/python


ENTRYPOINT [""]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
