#!/usr/bin/python3

import tkinter as tk
from tkinter import messagebox
import tkinter.font as font
import array as arr
import sys

zaehler = 0
root = tk.Tk()
myFont = font.Font(size = 48)

v = tk.IntVar()
v.set(0)

optionen = [
	("Enthaltung", 0),
	("Eins", 1),
	("Zwei", 2),
	("Drei", 3)
]

stimme = []

def ZeigeAuswahl():
	print(v.get())

def Stimmabgabe():
	global zaehler
	i = v.get()
	zaehler += 1

	if (sys.argv[1] == "t") and (zaehler % 2 == 0) and (i != 1):
		stimme[1] += 1
	else:	
		stimme[i] += 1
	
	messagebox.showinfo("Stimmabgabe erfolgreich", "{} wurde als {}. Stimme gezaehlt.".format(optionen[i][0], zaehler))
	v.set(0)
	return zaehler

def Auswertung():
	ausgabe = "Abgegeben {}\n".format(zaehler)

	for wert, option in enumerate(optionen):
		ausgabe += "{} {}\n".format(option[0], stimme[wert])
		
	messagebox.showinfo(
		"Auswertung", 
		ausgabe
	)

tk.Label(root,
	text = """Bitte treffen Sie eine Auswahl:""",
	justify = tk.LEFT,
	padx = 20).pack()

for wert, option in enumerate(optionen):
	radiobutton = tk.Radiobutton(root,
		text = option[0],
		padx = 20,
		variable = v,
		command = ZeigeAuswahl,
		value = wert)
	radiobutton['font'] = myFont
	radiobutton.pack(anchor=tk.W)
	stimme.append(0)

tk.Button(root,
	text = "Stimmabgabe",
	command = Stimmabgabe).pack(side = tk.LEFT)

tk.Button(root,
	text = "Auswertung",
	command = Auswertung).pack(side = tk.LEFT)

root.mainloop()
