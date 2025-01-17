*** Settings ***
Library         OpenShiftCLI
Resource        ../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource        ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource        ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource        ../../Resources/Page/LoginPage.robot
Resource        ../../Resources/Page/OCPLogin/OCPLogin.robot
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown


*** Variables ***
${RHOSAK_REAL_APPNAME}=         rhosak
${RHOSAK_DISPLAYED_APPNAME}=    OpenShift Streams for Apache Kafka


*** Test Cases ***
Verify That Login Page Is Shown When Reaching The RHODS Page
    [Tags]      Sanity
    ...         ODS-694
    [Setup]     Test Setup For Login Page
    Check OpenShift Login Visible

Verify Resource Link HTTP Status Code
    [Tags]    Sanity
    ...       ODS-531    ODS-507
    Click Link    Resources
    Sleep    5
    ${link_elements}=    Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=    Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    FOR    ${idx}    ${ext_link}    IN ENUMERATE    @{link_elements}    start=1
        ${href}=    Get Element Attribute    ${ext_link}    href
        ${status}=    Check HTTP Status Code    link_to_check=${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Verify Content In RHODS Explore Section
    [Documentation]    It verifies if the content present in Explore section of RHODS corresponds to expected one.
    ...    It compares the actual data with the one registered in a JSON file. The checks are about:
    ...    - Card's details (text, badges, images)
    ...    - Sidebar (titles, links text, links status)
    [Tags]    Sanity
    ...       ODS-488    ODS-993    ODS-749    ODS-352    ODS-282
    ...       KnownIssues
    ${EXP_DATA_DICT}=    Load Expected Data Of RHODS Explore Section
    Click Link    Explore
    Wait Until Cards Are Loaded
    Check Number Of Displayed Cards Is Correct    expected_data=${EXP_DATA_DICT}
    Check Cards Details Are Correct    expected_data=${EXP_DATA_DICT}

Verify Disabled Cards Can Be Removed
    [Documentation]     Verifies it is possible to remove a disabled card from Enabled page.
    ...                 It uses RHOSAK as example to test the feature
    [Tags]    Sanity
    ...       ODS-1081    ODS-1092
    ...       KnownIssues
    Enable RHOSAK
    Remove RHOSAK From Dashboard
    Success Message Should Contain    ${RHOSAK_DISPLAYED_APPNAME}
    Verify Service Is Not Enabled    app_name=${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot    after_removal.png

Verify License Of Disabled Cards Can Be Re-validated
    [Documentation]   Verifies it is possible to re-validate the license of a disabled card
    ...               from Enabled page. it uses Anaconda CE as example to test the feature.
    [Tags]    Sanity
    ...       ODS-1097   ODS-357
    Enable Anaconda    license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until RHODS Dashboard JupyterHub Is Visible
    Verify Service Is Enabled    ${ANACONDA_DISPLAYED_NAME}
    Close All Browsers
    Delete ConfigMap Using Name    redhat-ods-applications    anaconda-ce-validation-result
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Re-Validate License For Disabled Application From Enabled Page    app_id=${ANACONDA_APPNAME}
    Insert Anaconda License Key    license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Validate Anaconda License Key
    Success Message Should Contain    ${ANACONDA_DISPLAYED_NAME}
    Verify Service Is Enabled    ${ANACONDA_DISPLAYED_NAME}
    Capture Page Screenshot    after_revalidation.png
    [Teardown]    Remove Anaconda Commercial Edition Component

Verify CSS Style Of Getting Started Descriptions
    [Documentation]    Verifies the CSS style is not changed. It uses JupyterHub card as sample
    [Tags]    Smoke
    ...       ODS-1165
    Click Link    Explore
    Wait Until Cards Are Loaded
    Open Get Started Sidebar And Return Status    card_locator=${JH_CARDS_XP}
    Capture Page Screenshot    get_started_sidebar.png
    Verify JupyterHub Card CSS Style

Verify Documentation Link HTTP Status Code
    [Documentation]    It verifies the documentation link present in question mark and
    ...    also checks the RHODS dcoumentation link present in resource page.
    [Tags]    Sanity
    ...       ODS-327    ODS-492
    ${links}=  Get RHODS Documentation Links From Dashboard
    Check External Links Status     links=${links}

Verify Logged In Users Are Displayed In The Dashboard
    [Documentation]    It verifies that logged in users username is displayed on RHODS Dashboard.
    [Tags]    Sanity
    ...       ODS-354
    ...       Tier1
    Verify Username Displayed On RHODS Dashboard   ${TEST_USER.USERNAME}

Search and Verify GPU Items Appears In Resources Page
    [Tags]  ODS-1226
    Search Items In Resources Section   GPU
    Check GPU Resources

*** Keywords ***
Verify JupyterHub Card CSS Style
    [Documentation]     Compare the some CSS properties of the Explore page
    ...                 with the expected ones. The expected values change based
    ...                 on the RHODS version
    ${version-check}=  Is RHODS Version Greater Or Equal Than  1.7.0
    IF  ${version-check}==True
        CSS Property Value Should Be    locator=//pre
        ...    property=background-color    exp_value=rgba(240, 240, 240, 1)
        CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
        ...    property=margin-bottom    exp_value=8px
    ELSE
        CSS Property Value Should Be    locator=//pre
        ...    property=background-color    exp_value=rgba(245, 245, 245, 1)
        CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}//p
        ...    property=margin-bottom    exp_value=10px
    END
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-size    exp_value=24px
    CSS Property Value Should Be    locator=${SIDEBAR_TEXT_CONTAINER_XP}/h1
    ...    property=font-family    exp_value=RedHatDisplay
    ...    operation=contains

Test Setup For Login Page
    Set Library Search Order  SeleniumLibrary
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

Check OpenShift Login Visible
    ${result}=  Is OpenShift Login Visible
    IF  ${result}=='false'
        FAIL    OpenShift Login Is Not Visible
    END

Dashboard Test Setup
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Dashboard Test Teardown
    Close All Browsers

Check GPU Resources
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.9.0
    IF  ${version-check}==True
        ${elements}=  Get WebElements      //article
        ${len}=  Get Length    ${elements}
        Should Be Equal As Integers     ${len}  1
        Page Should Contain Element     //article[@id="python-gpu-numba-tutorial"]
        Page Should Contain Element     //a[@href="https://github.com/ContinuumIO/gtc2018-numba"]
    ELSE
        ${elements}=  Get WebElements      //article
        ${len}=  Get Length    ${elements}
        Should Be Equal As Integers     ${len}  0
        Page Should Not Contain Element     //article[@id="python-gpu-numba-tutorial"]
        Page Should Not Contain Element     //a[@href="https://github.com/ContinuumIO/gtc2018-numba"]
    END

