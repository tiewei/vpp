*** Settings ***
Library      OperatingSystem
#Library      RequestsLibrary
#Library      SSHLibrary      timeout=60s
#Library      String

Resource     ../../../variables/${VARIABLES}_variables.robot

Resource     ../../../libraries/all_libs.robot

Suite Setup       Testsuite Setup
Suite Teardown    Testsuite Teardown
Test Setup        TestSetup
Test Teardown     TestTeardown

*** Variables ***
${VARIABLES}=          common
${ENV}=                common
${SYNC_SLEEP}=         10s
${RESYNC_SLEEP}=       1s
${LIBMEMIF_IP1}=       192.168.1.2
${VPP2MEMIF_IP1}=      192.168.1.2
${VPP1MEMIF_IP1}=      192.168.1.1
${LIBMEMIF_IP2}=       192.168.2.2
${VPP2MEMIF_IP2}=       192.168.2.2
${VPP1MEMIF_IP2}=       192.168.2.1
# wait for resync vpps after restart
${RESYNC_WAIT}=        30s

*** Test Cases ***
Configure Environment
    [Tags]    setup
    Configure Environment 3

Show Interfaces Before Setup
    vpp_term: Show Interfaces    agent_vpp_1

Add Memif1 Interface On VPP1
    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif1    mac=62:61:61:61:61:61    master=false    id=0    ip=${VPP1MEMIF_IP1}    prefix=24    socket=memif.sock
    Sleep     ${SYNC_SLEEP}

Check Memif1 Interface Created On VPP1
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=0  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Modify Memif1 Interface On VPP1
    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif1    mac=62:61:61:61:61:62    master=false    id=0    ip=${VPP1MEMIF_IP2}    prefix=24    socket=memif.sock
    Sleep     ${SYNC_SLEEP}

Check Memif1 Interface On VPP1 is Modified
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:62
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:62  role=slave  id=0  ipv4=${VPP1MEMIF_IP2}/24  connected=0  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Create And Chek Memif1 On Agent Libmemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1   conn 0 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
    Should Contain     ${out}     interface ip: ${LIBMEMIF_IP1}
    Should Contain     ${out}     link: up

Check Memif1 Interface On VPP1 Connected To LibMemif
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Check Ping VPP1 -> Agent Libmemif 1
    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP1}


Remove VPP Nodes
    Remove All VPP Nodes
    Sleep    ${SYNC_SLEEP}
    Add Agent VPP Node    agent_vpp_1
    #Add Agent VPP Node    agent_vpp_2
    Sleep    ${RESYNC_WAIT}

Check Memif1 Interface On VPP1 Connected To LibMemif After Resync
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Check Ping VPP1 -> Agent Libmemif 1 After Resync
    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP1}

##############################################################################


Delete Memif On Agent Libmemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1   del 0
    Sleep     ${SYNC_SLEEP}

Check Memif1 Interface On VPP1 Disconnected After Master Deleted
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=0  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Create Memif1 On Agent Libmemif 1 Again
    ${out}=      lmterm: Issue Command    agent_libmemif_1   conn 0 1
    Sleep     ${SYNC_SLEEP}

Check Memif1 Interface On VPP1 Connected After Master Deleted and Created
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Check Ping VPP1 -> Agent Libmemif 1 After Delete and Create
    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP1}

####### Here VPP crashes
#Modify Memif1 Interface On VPP1 While Connected
#    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif1    mac=62:61:61:61:61:62    master=false    id=0    ip=${VPP1MEMIF_IP2}    prefix=24    socket=memif.sock
#    Sleep     ${SYNC_SLEEP}

#Check Memif1 Interface On VPP1 Modified
#    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:62
#    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:62  role=slave  id=0  ipv4=${VPP1MEMIF_IP2}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock
#
#Check Ping VPP1 -> Agent Libmemif 1 After Memif1 Modified
#    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP1}

############################################################
#Delete Memif On Agent Libmemif 1
#    ${out}=      lmterm: Issue Command    agent_libmemif_1   del 0
#
#Modify Memif1 Interface On VPP1 After Slave Delete
#    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif1    mac=62:61:61:61:61:62    master=false    id=0    ip=${VPP1MEMIF_IP2}    prefix=24    socket=memif.sock
#    Sleep     ${SYNC_SLEEP}

##### Here VPP crashes
#Check Memif1 Interface On VPP1 Modified After Slave Delete 2
#    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:62
#    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:62  role=slave  id=0  ipv4=${VPP1MEMIF_IP2}/24  connected=0  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock

Remove Agent Libmemif 1
     Remove Node      agent_libmemif_1
     Sleep    ${SYNC_SLEEP}

Add Libmemif Node Again
    Add Agent Libmemif Node    agent_libmemif_1
    Sleep    ${RESYNC_WAIT}

Create And Check Memif1 On Agent Libmemif 1 After node restart
    ${out_c}=      lmterm: Issue Command    agent_libmemif_1   conn 0 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
    Log Many      ${out_c}    ${out}
    Should Contain     ${out}     interface ip: ${LIBMEMIF_IP1}
    Should Contain     ${out}     link: up

Check Memif1 Interface On VPP1 Connected After Node Restart
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show

Create Memif2 On Agent Libmemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1   conn 1 1
    #Should Contain     ${out}     INFO: memif connected!

Check Memif 1 and Memif2 On Agent LibMemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP2}
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP1}
    Should Contain      ${out}     link: up
    Should Contain      ${out}     link: down

Check Memif1 Interface On VPP1 Connected After Second Libmemif Added
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:61:61
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif1  mac=62:61:61:61:61:61  role=slave  id=0  ipv4=${VPP1MEMIF_IP1}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show

############################################################################
##### Here VPP crashes
#Add Memif2 Interface On VPP1
#    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif2    mac=62:61:61:61:51:51    master=false    id=1    ip=${VPP1MEMIF_IP2}    prefix=24    socket=memif.sock
#    Sleep     ${SYNC_SLEEP}
#
#Check Memif2 Interface Created On VPP1
#    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:51:51
#    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif2  mac=62:61:61:61:51:51  role=slave  id=0  ipv4=${VPP1MEMIF_IP2}/24  connected=1  enabled=1  socket=${AGENT_LIBMEMIF_1_MEMIF_SOCKET_FOLDER}/memif.sock
#
#Check Memif 1 and Memif2 On Agent LibMemif 1
#    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
#    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP2}
#    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP1}
#    Should Contain      ${out}     link: up
#    Should Not Contain  ${out}     link: down

#Delete Memif2 Interface On VPP1 After Resync
#    vpp_ctl: Delete VPP Interface    node=agent_vpp_1    name=vpp1_memif2
#    vpp_term: Interface Is Deleted    node=agent_vpp_1    mac=62:61:61:61:51:51

Delete Memif1 Interface On VPP1
    vpp_ctl: Delete VPP Interface    node=agent_vpp_1    name=vpp1_memif1
    vpp_term: Interface Is Deleted    node=agent_vpp_1    mac=62:61:61:61:61:61

Check Memif 1 and Memif2 On Agent LibMemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP2}
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP1}
    Should Contain      ${out}     link: down

Add Memif2 Interface On VPP1
    vpp_ctl: Put Memif Interface With IP    node=agent_vpp_1    name=vpp1_memif2    mac=62:61:61:61:51:51    master=slave    id=1    ip=${VPP1MEMIF_IP2}    prefix=24    socket=memif.sock
    Sleep     ${SYNC_SLEEP}

Check Memif2 Interface Created On VPP1
    vpp_term: Interface Is Created    node=agent_vpp_1    mac=62:61:61:61:51:51
    vat_term: Check Memif Interface State     agent_vpp_1  vpp1_memif2  mac=62:61:61:61:51:51  role=slave  id=1  ipv4=${VPP1MEMIF_IP2}/24  connecte

Check Memif 1 and Memif2 On Agent LibMemif 1
    ${out}=      lmterm: Issue Command    agent_libmemif_1    show
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP2}
    Should Contain      ${out}     interface ip: ${LIBMEMIF_IP1}
    Should Contain      ${out}     link: up
    Should Contain      ${out}     link: down

Check Ping VPP1 Memif2 -> Agent Libmemif 1 After Delete and Create
    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP2}

Check Ping VPP1 Memif1 -> Agent Libmemif 1 After Delete and Create
    vpp_term: Check Ping    agent_vpp_1    ${LIBMEMIF_IP1}


*** Keywords ***
TestSetup
    Make Datastore Snapshots    ${TEST_NAME}_test_setup

TestTeardown
    Make Datastore Snapshots    ${TEST_NAME}_test_teardown