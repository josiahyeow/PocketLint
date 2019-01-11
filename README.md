# PocketLint

PocketLint is an iOS application that aims to become your virtual pocket by providing a place to quickly
capture and store photos of information you find throughout your day. PocketLint hopes to free up your
physical pockets leaving only ‘lint’ left in them.

Throughout our day we may take a lot of “throwaway photos” which are images that we quickly take to
save some information but don’t want to keep in our phone’s gallery indefinitely. Examples of these
“throwaway photos” are things like brochures, business cards, advertisements, event posters etc... We
would throw these images away after we’ve acted upon the information inside them but currently they
become lost in our phone’s gallery mixed in between our precious photos of our friends and family.
The focus of PocketLint is to build a mobile application that improves the process of capturing, storing,
finding and managing these “throwaway photos”. Users will be able to quickly take a photo and PocketLint
will extract its content highlighting important information such as URLs, email addresses, phone numbers
and more. By storing these photos in PocketLint, users will also be encouraged to delete these images
once they are no longer needed which allows users to not only free up their physical pockets but also their
phone’s internal storage.

## Application Functionality
There are several main features of PocketLint, these include:
### Photo Capture
Users need to be able to quickly take photos of the information they want to capture. The button to open
up the camera will be easily accessible from the main screen of the app and will use iOS/Android’s native
camera interface so it’s familiar to the users. Once the user takes a photo, they will be given a preview of it
where they can either and a caption and save or retake the photo. Upon saving, the image will be added to
the main screen at the top of the list.
### Photo Viewing
As the purpose of the app is to allow users to quickly locate the images they want to see, photos taken in
PocketLint will be displayed in reverse chronological order so the latest image can be found first. The
images will be presented in a large thumbnail format so the contents of the image can be recognised
without the need of opening them.
When an image is opened, it will be displayed with more information below it (gathered from image
recognition or manually added).
### Photo Management
One of the purposes of the app is to reduce photo clutter to save storage space. PocketLint will
persistently display the number of photos that are stored to encourage the user to delete unused images.
The metaphor of a physical pocket that has limited space is the point of the app here.
Users can easily batch delete photos that have already been opened after capture. Users will also be able
to delete individual photos from the main feed with a swipe to the left. The option to undo deletions will
also be present to avoid accidental data loss.
### Cloud Photo Storage (Firebase Storage)
Photos taken in the PocketLint app will also be uploaded to the cloud and synchronised across devices.
This will allow users to easily access their information no matter what device they are on. It also provides
the security that their photos are not lost if they delete the app or lose their device.
### Image recognition (Firebase ML Kit)
Due to the busy nature of the target audience, users may not have the time to add titles and descriptions
of the photos they are taking. To solve this, PocketLint will use image recognition technology to figure out
the contents of each photo and extract important information such as URLs, addresses and phone
numbers which then can be acted upon. (e.g. calling a phone number or adding it to the Contacts app).
