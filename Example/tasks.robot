*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Archive
Library             RPA.Excel.Files
Library             RPA.FileSystem
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Windows
Library             XML
Library             OperatingSystem


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}    ${OUTPUT_DIR}${/}receipt


*** Tasks ***
Insert the sales data for the week and export it as a PDFMinimal task
    Open the intranet website
    Click Button    OK
    Download the Excel file
    Fill the form using the data from the Excel file
    Create ZIP package from PDF files


*** Keywords ***
Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Fill the form using the data from the Excel file
    ${orders}=    Read table from CSV    orders.csv    header=True
    # ${varhead}=    RPA.Tables.Get table column    ${orders}    column=Head
    # ${varbody}=    RPA.Tables.Get table column    ${orders}    column=Body
    # FOR    ${orders}    IN    @{orders}

    FOR    ${orders}    IN    @{orders}
        Fill and submit the form for one person    ${orders}
    END

Fill and submit the form for one person
    [Arguments]    ${orders}

    # ${varhead}=    RPA.Tables.Get table column    ${orders2}    column=Head
    # FOR    ${varhead}    IN    @{varhead}
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    class=form-control    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Sleep    3
    Click Button    order

    # ${res}=    Does Page Contain Element    class=alert-danger
    # IF    ${res} == True
    # END

    ${res}=    Does Page Contain Element    class=alert-danger
    WHILE    ${res} == True
        Sleep    2
        Click Button    order
        ${res}=    Does Page Contain Element    class=alert-danger
    END

    Wait Until Element Is Visible    id:order-another
    Export the table as a PDF
    Sleep    1
    Click Button    order-another

    Wait Until Element Is Visible    class=btn-dark
    Sleep    1
    Click Button    OK

#    Collect the results
    # RPA.Browser.Selenium.Screenshot    class=badge-success    ${OUTPUT_DIR}${/}receipt/success.jpg

Export the table as a PDF
    Wait Until Element Is Visible    id:receipt

    ${class_value}=    RPA.Browser.Selenium.Get Text    class=badge-success

    ${sales_results_html}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML

    # Wait until robot image is shown
    Sleep    3
    RPA.Browser.Selenium.Screenshot    id=robot-preview-image    ${OUTPUT_DIR}${/}receipt/success.jpg

    HTML To PDF    ${sales_results_html}    ${OUTPUT_DIR}${/}receipt/sales_results_${class_value}.pdf

    Open Pdf    ${OUTPUT_DIR}${/}receipt/sales_results_${class_value}.pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}receipt/success.jpg
    ...    ${OUTPUT_DIR}${/}receipt/sales_results_${class_value}.pdf
    Save PDF    ${OUTPUT_DIR}${/}receipt/sales_results_${class_value}.pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}/receipts.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Log out and close the browser
    Click Button    Log out
    Close Browser
