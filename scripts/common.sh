# test if variable is set
function test_var() {
    if [ -z ${!1+x} ]
    then 
        echo "$1 is unset"
        exit -1
    else 
        echo "$1 is set to '${!1}'"
        return 0
    fi
}

# test is dependency is available
function test_dependency() {
    if ! command -v $1 &> /dev/null
    then
        echo "install $1"
        exit -1
    else
        return 0
    fi
}