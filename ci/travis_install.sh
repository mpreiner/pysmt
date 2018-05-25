#!/bin/bash
set -ev

#
# Skip Install if Python 2.7 or PyPy and not a PR
#
if [ "${TRAVIS_PULL_REQUEST}" == "false" ] && [ "${TRAVIS_BRANCH}" != "master" ]; then
    echo "Regular Push (not PR) on non-master branch:"
    if [ "${TRAVIS_PYTHON_VERSION}" == "2.7" ]; then
        echo "Skipping Python 2.7"
        exit 0
    fi
    if [ "${TRAVIS_PYTHON_VERSION}" == "pypy" ]; then
        echo "Skipping Python PyPy"
        exit 0
    fi
    if [ "${PYSMT_SOLVER}" == "all" ]; then
        echo "Skipping 'all' configuration"
        exit 0
    fi
    if [ "${TRAVIS_OS_NAME}" == "osx" ]; then
        echo "Skipping MacOSX build"
        exit 0
    fi
fi

PIP_INSTALL="python -m pip install --upgrade"
if [ "${TRAVIS_OS_NAME}" == "osx" ]; then
    # On OSX we need to upgrade pip as the image version is too old ...
    curl https://bootstrap.pypa.io/get-pip.py | sudo python
    PIP_INSTALL="python -m pip install --user --upgrade"
fi

$PIP_INSTALL configparser
$PIP_INSTALL six
$PIP_INSTALL cython;

if [ "${PYSMT_SOLVER}" == "all" ] || [ "${PYSMT_SOLVER}" == *"btor"* ];
then
    $PIP_INSTALL python-coveralls;
fi

if [ "${PYSMT_GMPY}" == "TRUE" ];
then
    $PIP_INSTALL gmpy2;
fi

# Adding Python 3.6 library path to GCC search
if [ "${TRAVIS_PYTHON_VERSION}" == "3.6" ]; then
    export LIBRARY_PATH="/opt/python/3.6.3/lib:${LIBRARY_PATH}"
    export CPATH="/opt/python/3.6.3/include/python3.6m:${CPATH}"
fi


#
# Install Solvers
#
PYSMT_SOLVER_FOLDER="${PYSMT_SOLVER}_${TRAVIS_OS_NAME}"
PYSMT_SOLVER_FOLDER="${PYSMT_SOLVER_FOLDER//,/$'_'}"
export BINDINGS_FOLDER=${HOME}/python_bindings/${PYSMT_SOLVER_FOLDER}

mkdir -p ${BINDINGS_FOLDER}
python install.py --confirm-agreement --bindings-path ${BINDINGS_FOLDER}
eval `python install.py --env --bindings-path ${BINDINGS_FOLDER}`

if [ "${PYSMT_SOLVER}" == "all" ] || [ "${PYSMT_SOLVER}" == *"z3_wrap"* ]; then
    python install.py --z3 --conf --force;
    cp -v $(find ~/.smt_solvers/ -name z3 -type f) pysmt/test/smtlib/bin/z3;
    chmod +x pysmt/test/smtlib/bin/z3;
    mv pysmt/test/smtlib/bin/z3.solver.sh.template pysmt/test/smtlib/bin/z3.solver.sh ;
fi

if [ "${PYSMT_SOLVER}" == "all" ] || [ "${PYSMT_SOLVER}" == *"msat_wrap"* ];
then
    python install.py --msat --conf --force;
    cp -v $(find ~/.smt_solvers/ -name mathsat -type f) pysmt/test/smtlib/bin/mathsat;
    mv pysmt/test/smtlib/bin/mathsat.solver.sh.template pysmt/test/smtlib/bin/mathsat.solver.sh ;
fi


# On OSX install nosetest
if [ "${TRAVIS_OS_NAME}" == "osx" ]; then
    $PIP_INSTALL nose
fi
