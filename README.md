
This repository has two independently branded systems, one called **Catalyst** and the other one called **DocNet** (Multi-user **Doc**umentation **Net**work). If you are coming from the Guardian, you are looking for [DocNet](documentation/DocNet.md) 🙂


Q: What exactly is the relationship betweeen Catalyst and DocNet ? 🤔

- DocNet is simply a limited version of Catalyst that runs on an independent DataStore. They share the same code, but when DocNet runs, some features are not enabled (and not all the data model is used). Note that despite being a *limited version*, DocNet has an important ability that Catalyst doesn't: multiple instances of DocNet can synchronise and share their data updates. (Giving DocNet its distributed multi-users capabilities.) 


Q: What is the latest in terms of roadmap ? 👩‍💻

- As of July 2020, most of the effort has recently been put into reorganizing Catalyst's data model and make its DocNet subset multi-user. 
- Catalyst and DocNet are going to be re-written in Go by the end of 2020.
- DocNet features that may appear in the future include, but are not limited to:
	- Enablying end to end encryption between users.
	- Possibly user credentials management. 
	- Possibly some sort of a web interface (for better knowledge graph visualisation).
	- Shipping DocNet as an independant program independant of Catalyst, but this will only happen after the entire system has been rewritten in Go.