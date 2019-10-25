# minidlna
miniDLNA(Apply patches to enable thumbnails for Video) docker image 

## usage

    # docker build -t minidlna .
    # docker run -d --name minidlna --net host --mount type=bind,src=/var/lib/minidlna,dst=/opt localhost/minidlna
