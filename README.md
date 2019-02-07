This app is made to demonstrate a problem with the firebase_ml_vision package
Instructions:
1.	Prepare a text to scan. For example “Hello World” printed on a sheet of paper.
2.	Press the Start imagestream button.
3.	With the text clearly visible in the preview window, press the Stop imagestream button.
4.	After a few seconds, press the Scan last image button.
5.	Watch the console. The displayed text and the boundary box should be the same all the time, but it is not. 
6.	For me, the app nearly always ends with a Fatal signal 11. Sometimes this comes on the first scan, but usually after a dozen or so. This on a Samsung Galaxy S4 with Android 5.0.1 API 21.

A few lines may have to be changed, depending on the mobile used:

Line 52: Change quarterTurns if needed to get the preview window right.

Line 97: With the Galaxy S4, I must do a horizontal flip to get the scanner to recognize the text. This may not be your case. If not, comment out line 118 and uncomment line 119. (I did this, and then scanned a text which is symmetric, like TOMOT – the problem still occurred.)

Line 115: Change rotation180 to rotation0 if necessary.
