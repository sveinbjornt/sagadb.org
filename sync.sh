#!/bin/sh

rsync -av --delete web/html root@sagadb.org:/www/dev.sagadb.org/html
