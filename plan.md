## AI Assisted DSS

Overview

AI assisted DSS is a system that uses AI to assist in decision making. It can be used in various fields such as healthcare, finance, and education or any field that requires decision making.

The AI part is the part where UX is played. 

Flow :
    - User will be asked what you want to decide
    - AI will ask for the information needed to make the choice clear
        - AI will ask for the criteria
        - AI will ask for the weight of each criteria and type benefit or cost
        - AI will ask for the alternative
        - AI will ask for the value of each alternative for each criteria
    - AI will make the ask what method is will be used to make the decision
        - SAW (with user friendly explanation)
        - WP (with user friendly explanation)
        - TOPSIS (with user friendly explanation)
    - Show the table of the choice and the rank for each method ready for the decision
    - AI will explain in user friendly manner base on the decision

Stack
 - Flutter
 - Firebase
 - AI (Use the free deepseek API) this may need to save the key in the db in firebse then later use in client side (decide what is the safest way)


Functionalities is the first prios. its like a simple chat that need to shown table (after all criteria is met) save to memory in db of the conversation so user be able to recall or changes.
all database is stored in firebase.
Security is the 2 priority. it will be done after the functionalities is done.

IMPORTNAT

self learning and healing is your behaviour. 

firebase

flutterfire configure --project=primaadi
