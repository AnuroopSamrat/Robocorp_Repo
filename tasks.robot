*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Ask assistant name
    Get Url From Local Vault
    Open the robot order website
    Download an Excel file
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${receipt_pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${robot_screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${robot_screenshot}    ${receipt_pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close All Browsers


*** Keywords ***
Open the robot order website
    ${URL}=    Get Url From Local Vault
    Log    ${URL}
    Open Available Browser    ${URL}

Download an Excel file
    # This task executes these three keywords:
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=True    delimiters=","
    RETURN    ${orders}

Close the annoying modal
    #Click Button    //button[@class="btn btn-dark"]
    Click Button When Visible    locator=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[3]

Fill the form
    [Arguments]    ${row}
    #Select From List By Value    head    ${row}[Head]
    Select From List By Value    //*[@id="head"]    ${row}[Head]
    #Select Radio Button    form-group:id-body-${row}[Body]    ${row}[Body]
    Click Element    //input[@type='radio' and @name='body' and @value='${row}[Body]']
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@name="address"]    ${row}[Address]

Preview the robot
    Click Button    //*[@id="preview"]

Submit the order
    Click Button    //*[@id="order"]
    ${error}=    Does Page Contain Element    //div[@class="alert alert-danger"]
    IF    ${error}    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${OrderNumber}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${OrderNumber}_receipt.pdf
    RETURN    ${OUTPUT_DIR}${/}${OrderNumber}_receipt.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}${orderNumber}_robot.png
    RETURN    ${OUTPUT_DIR}${/}${orderNumber}_robot.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${robot_screenshot}    ${receipt_pdf}
    ${images}=    Create List    ${robot_screenshot}
    Add Files To Pdf    ${images}    ${receipt_pdf}    append=True

Go to order another robot
    Click Button    //*[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${OUTPUT_DIR}${/}robot_receipts.zip    include=*.pdf    exclude=/.*

Get Url From Local Vault
    ${data}=    Get Secret    Order_Url
    Log    ${data}[url]    console=True
    RETURN    ${data}[url]

Ask assistant name
    Add text input    name    label=Whats your name?
    ${response}=    Run dialog
    Log    ${response}[name]    console=True
