# Automatically create JAVA_HOME
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
# Add py4j libraries to pythonpath
export PYTHONPATH=$SPARK_HOME/python:$(ls $SPARK_HOME/python/lib/py4j*.zip)
