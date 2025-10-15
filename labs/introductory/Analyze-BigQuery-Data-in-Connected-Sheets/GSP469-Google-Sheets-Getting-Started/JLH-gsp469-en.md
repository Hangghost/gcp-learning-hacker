# GSP469 - Google Sheets: Getting Started

## Lab Title
Google Sheets: Getting Started

## Lab Overview
Google Sheets is a cloud-based application that provides advanced, fast, online spreadsheets. Designed with collaboration and convenience in mind, you can analyze data with charts and filters, handle task lists, create project plans, and more with your team from any online device. All changes are saved automatically and in one place. Use Google Sheets to create, edit, and collaborate wherever you are.

## Learning Objectives
In this lab, you use Sheets to do the following:
- Create, update, and customize a spreadsheet
- Analyze data
- Share a spreadsheet
- Access other apps from a spreadsheet

## Prerequisites
- Google account
- Internet connection
- Web browser

## Estimated Time
45 minutes

## Lab Steps

### Step 1: Open a sample spreadsheet

**Description:**
Open a sample spreadsheet to familiarize yourself with the Google Sheets interface and features.

**Instructions:**
1. Click [Explore this data](https://docs.google.com/spreadsheets/d/19iLO-XbrqqWRuqphkXTax0lFn71NW6crJK504JvAxoU/edit#gid=599358521) to open a sample spreadsheet
2. Make a copy. Select **File > Make a copy**
3. Leave the **Name** and **Folder** fields at the default values and click **Make a copy**

**Expected Result:**
Successfully opened and copied the sample spreadsheet. You now have your own editable version.

### Step 2: Export spreadsheet data

**Description:**
Export the spreadsheet data to your local device for use later in this lab.

**Instructions:**
1. Select **File** > **Download** > **Comma-separated values (.csv)**
2. Close the browser tab to close this spreadsheet
3. Also close the original `Explore this data (budget request by department)` spreadsheet if it is still open

Only these lab instructions and Sheets are open in the remaining browser tabs or windows.

4. Find the .csv file you downloaded to your local computer and rename it `exported-data`

**Expected Result:**
Successfully exported the spreadsheet as a CSV file and renamed it to `exported-data`.

### Step 3: Import a spreadsheet

**Description:**
Learn how to import data from other spreadsheets and convert it to Sheets format.

**Instructions:**
1. Open [Google Drive](https://drive.google.com/) in a new browser tab
2. In the upper left corner, click **New** > **File Upload**
3. Choose `exported-data.csv` from your computer to add it to Drive

Alternatively, you can drag the csv file from your local computer to your Drive.

4. To convert `exported-data.csv` to a Google Sheet:
   - In Drive, right-click `exported-data.csv`
   - Select **Open with** and choose **Google Sheets**

When you import or convert a spreadsheet, Sheets creates a copy of the original file in Sheets format. You can then edit the new file in your browser as you would with any other Sheet.

**Supported file types:**
If you have other types of spreadsheets, try importing it to Drive and converting it to a Google Sheet.

**Note:** Supported files include .xls, .xlsx, .xlt, .ods, .csv, .tsv, .txt, and .tab.

If you upload a Microsoft® Excel® spreadsheet into Drive, you can also update them without converting to Sheets.

**Expected Result:**
Successfully imported and converted the CSV file to Google Sheets format.

### Step 4: Create a spreadsheet

**Description:**
Learn how to create a new spreadsheet, enter and edit data, customize your spreadsheet, and work with multiple sheets.

#### Create a new spreadsheet

1. Go back to the MyDrive browser tab
2. Click on the Google apps icon and select **Google Sheets**

3. In the **Start a new spreadsheet** section, click the plus sign to create a blank template

#### Enter and edit your data

1. Rename your spreadsheet: click **Untitled spreadsheet** and enter `important-data`
2. Enter a header row and data: click a cell, type content, and then press **Enter** or click outside of the cell

Example spreadsheet:

Notice in the example spreadsheet above, the numbers in column C have a currency format applied. To do this you would:
- Select the C column
- Choose **Format** > **Number** > **Currency** from the menu bar

3. Insert more items, click **Insert** and experiment by adding charts, images, drawings, functions, notes, and more

**Note:** To see which functions are available, see the [Google spreadsheets function list](https://support.google.com/docs/table/25273)

4. (Optional) Use the Explore feature to analyze your spreadsheet
   - Experiment with analysis suggestions
   - Can you put a pie chart in your spreadsheet?

#### Customize your spreadsheet

Experiment with the spreadsheet you made in the last section. Select cells in your spreadsheet and then format them using the toolbar options.

#### Work with rows, columns, and cells

1. **Add rows, columns, and cells** — Select a cell or block of cells. Then, on the menu bar, click **Insert** and choose where to add the row column, or cells
2. **Delete or hide rows and columns** — Right-click the row number or column letter and select **Delete** or **Hide**
3. **Delete a cell or a block of cells** — Select the cells you want to delete. Click **Edit** > **Delete cells and shift up**, or **Edit** > **Delete cells and shift left**
4. **Move rows and columns** — Click the row number or column letter to select it. Then, drag it to a new location
5. **Freeze header rows and columns** — Keep some data in the same place as you scroll through the rest of your spreadsheet. On the menu bar, click **View** > **Freeze** and choose an option

#### Work with multiple sheets

**Rename a sheet:**
1. At the bottom of your spreadsheet, double-click `Sheet1`
2. When you see it highlighted, rename it **Overview**

**Add a sheet:**
1. At the bottom left of your spreadsheet, click **Add Sheet** (+) to add another sheet
2. Name this sheet `Detail`

**Copy a sheet:**
1. At the bottom of your spreadsheet, click the down arrow of `Detail`
2. Select **Duplicate**

**Delete a sheet:**
1. At the bottom of your spreadsheet, click the down arrow of `Copy of Detail`. Select **Delete**
2. Click **OK** to confirm

**Expected Result:**
Successfully created and customized a spreadsheet, including data entry, formatting, and multi-sheet management.

### Step 5: Share and collaborate

**Description:**
Learn how to share spreadsheets with your team and collaborate, including adding comments, replies, and real-time chat.

#### Share spreadsheets

**Share a file or folder with specific people:**
You can only share files that you own or have edit access to.

1. Using the same `important-data` file, in Sheets, in the upper right, select **Share**
2. Under **Share with people and groups**, enter the email address of the person or group you want to share with
3. Click **Editor** (on the right) and choose the access level:
   - **Editor**: Collaborators can add and edit content as well as add comments
   - **Commenter** (Select files only): Collaborators can add comments, but can't edit content
   - **Viewer**: People can view the file, but cannot edit or add comments
4. Click **Send**

Everyone you share with receives an email with a link to the file or folder.

**Note:** You may receive a message that the admin policy prohibits sharing items to a particular email address. You can ignore it as this lab is for demonstration purposes only.

5. (Optional) To add a note to the email, enter your note. To skip sending an email, uncheck the **Notify people** box

**Share a link to a file or folder:**
Send other people a link to a file or folder so that anyone with the link can open it. When you share a link, your name appears as the owner.

You can only share files that you own or have edit access to.

1. In Sheets, in the upper right, select **Share**
2. Click **Restricted** and select **Qwiklabs**
3. Click **Viewer** (to the right of Qwiklabs) and choose the access level:
   - Editor: Collaborators can add and edit content as well as add comments
   - Commenter (Select files only): Collaborators can add comments, but can't edit content
   - Viewer: People can view the file, but not edit or add comments
4. Click **Copy link**
5. Click **Done**
6. You can now paste the link in an email or any place you want to share it

**Expected Result:**
Successfully set up sharing permissions for the spreadsheet and copied the share link.

#### Unshare spreadsheets

**Stop sharing a file or folder you own:**
1. In Drive, select the shared file or folder
2. Right-click on the file and select **Share**
3. If you had successfully shared the file to a person in the previous step, click the access level (i.e. Editor, Viewer, Commenter) next to the person you want to stop sharing the file or folder with and click **Remove**
4. Click **Save changes**

**Delete a link to a file or folder you own:**
When you delete a link to a file or folder that you own, the only people who can still see it are you and anyone you share it with.

1. In Drive, right-click on a file or folder and select **Share**
2. Click **Qwiklabs** and select **Restricted**
3. Click **Done**

**Expected Result:**
Successfully unshared the spreadsheet and removed access permissions.

#### Add comments and replies

1. In an open spreadsheet, select a cell or cells you'd like to comment on
2. Do one of the following:
   - Click the comment icon in the formatting bar at the top
   - Right click on the cell or cells and click **Comment**
3. Enter your comment in the box
4. (Optional) To direct your task or comment to a specific person, enter an At Sign (@) followed by their email address. You can add as many people as you want. Each person will get an email with your comment and a link to the file
5. (Optional) To assign the comment to a specific person, check the **Assign to** box
6. Click **Comment** or **Assign**

**Expected Result:**
Successfully added comments to the spreadsheet and assigned them to relevant people.

#### Chat with people directly with Google Chat (information only)

**Note:** This feature requires that you and at least one other person have this sheet open at the same time. Because the admin policy for this lab prohibits you from sharing, this feature is not available for you in this lab.

You can collaborate in real time over Google Chat, too. If more than one person has your spreadsheet open, just click **Show chat** to open a group chat.

You can get instant feedback without ever leaving your spreadsheet.

#### Present your spreadsheet directly from Google Meet (information only)

**Note:** This feature requires that you and at least one other person have this sheet open at the same time. Because the admin policy for the lab prohibits you from sharing, this feature is not available for you in this lab.

To discuss your spreadsheet with team members, open Google Meet directly from Sheets to present and discuss your data. Click **Join a call here or present this tab to a call** to start or join a meeting.

**Expected Result:**
Understanding of how to use collaboration features for real-time interaction with team members.

## Verification Steps

1. Confirm you have successfully opened and copied the sample spreadsheet
2. Confirm you have exported the spreadsheet as CSV and renamed it to `exported-data`
3. Confirm you have successfully imported and converted the CSV file to Google Sheets format
4. Confirm you have created and customized a spreadsheet named `important-data`
5. Confirm you have set up sharing permissions for the spreadsheet and copied the share link
6. Confirm you understand how to add comments and collaboration features

## Troubleshooting

### Common Issues and Solutions

- **Issue: Unable to open sample spreadsheet link**
  - **Solution:** Ensure you are logged into your Google account and check your internet connection

- **Issue: Unable to upload CSV file to Google Drive**
  - **Solution:** Check file size (should be less than 5TB) and ensure file format is correctly .csv

- **Issue: Unable to convert CSV to Google Sheets**
  - **Solution:** Right-click the file and select "Open with > Google Sheets", or open from the Google Sheets app

- **Issue: Unable to share spreadsheet**
  - **Solution:** Ensure you own the file or have edit permissions, and check the recipient's email address

- **Issue: Comment feature not working**
  - **Solution:** Ensure the spreadsheet is shared and collaborators have appropriate permissions

## Cleanup Steps

This lab does not involve creating GCP resources, so no special cleanup is required. However, it is recommended to:

1. Delete test spreadsheets if no longer needed
2. Remove uploaded CSV files from Google Drive
3. Check and clean up locally downloaded files

## Additional Resources

- [Google Sheets Official Documentation](https://support.google.com/docs/answer/6000292)
- [Google Sheets Function List](https://support.google.com/docs/table/25273)
- [Google Drive Help](https://support.google.com/drive)
- [Google Collaboration Tools Guide](https://support.google.com/a/users/answer/9282959)

## Notes

This is a purely educational lab focused on familiarizing users with Google Sheets basic functionality. While titled as a "GCP Skill Badge", it is actually a Google Workspace application learning experience. The lab emphasizes collaboration features, which are a core characteristic of Google Workspace.

Mobile app links mentioned in the lab:
- Android: [Google Sheets](https://play.google.com/store/apps/details?id=com.google.android.apps.docs.editors.sheets)
- iOS: [Google Sheets](https://itunes.apple.com/app/google-sheets/id842849113)

Completion recorded: 2025-10-15
