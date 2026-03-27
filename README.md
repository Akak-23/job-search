# Minimum Requirements

## Job Search

### Job Overview
- ~~List all available job postings with just the information that's helpful and relevant in a space-constrained list view~~
- ~~This list should be searchable and filterable by categories you deem relevant. Don't make a separate view for that.~~
- ~~This list should be sortable by categories you deem relevant.~~
- ~~Searches/Filters should be savable, saved searches/filters should be easily applicable~~
  - ~~Managing saved searches/filters should have its own screen~~

### Job Details
- ~~Show all the information you have for a job posting~~
- ~~**NB:** in our cursory examination of the Jobsuche API, we didn't see a way to get a JobDetails object, which will probably make you miss some data that you mentioned in your concept. We currently expect this and considered it in the workload we give you. If you have found another way to access this in a way that will increase your implementation effort, talk to us to discuss further steps.~~
- ~~Send a job to the Application Manager (see below)~~

## Application Manager
- ~~We envision that this section of the app is used to assist a user in keeping track of the various stages a job offer can be in during the application process. These stages should be represented here in an intuitive way. Use more granular stages than you outlined in your navigation tree, e.g.: saved, preparing application, application sent, follow-up phone call, interview, negotiations, accepted, … (these would probably be set manually by the user; no automatic process is needed)~~
  - ~~A job that's sent here from the Job Details Screen is first categorized as saved~~
  - ~~The user can move jobs between these different stages. It should be able to be moved into both directions, e.g. sometimes there's another follow-up call after an interview, then another interview could follow~~
- ~~Add useful tools to a job offer in these stages~~
  - ~~If a job offer is in the phone call or interview stages, allow the user to add notes for those respectively. Think of useful information like Date/Time and correspondent that is logged with that~~
  - ~~If a job is in the preparing application stage, offer to generate a single PDF out of the user-selected resources that can be sent to apply, e.g. combine the cover letter, CV and the relevant certificates into one document~~

## Profile
- ~~Edit the information that will be used to generate documents, e.g. CVs or (optionally, see below) cover letters~~
- ~~Store documents you may want to include in an application, e.g. certificates or letters of reference~~

## CV Generator
- ~~From the user's profile a nice looking CV PDF should be generated and sharable (e.g. via email)~~
- ~~Integrate the CV generator in a fitting way, with a good usability~~
  - ~~maybe as part of the profile~~
  - maybe as part of the Application Manager  
  - maybe both

# Nice To Have
- ~~Analogous to the CV generator, a cover letter generator, that uses AI to create a cover letter that's fitting for the role and company that the user wants to apply to~~
- ~~Share a job posting~~

# We Do Not Recommend You To
- Implement functionality for employers
- There is no use for visibility settings for this app concept