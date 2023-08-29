# https://blog.finxter.com/generate-a-simple-pdf-using-python-reportlab-9-steps/

from reportlab.platypus import *
from reportlab.lib.styles import *
from reportlab.lib import *
from reportlab.platypus import *
import pandas as pd
import math 

df_cars = pd.read_csv('cars.csv', sep=';').head(60)
df_data = [df_cars.columns[:,].values.astype(str).tolist()] + df_cars.values.tolist()
pg_data = df_data[1:]

elements = []
recs_pg = 39
tot_pgs = math.ceil(len(df_data) / recs_pg)

styles = getSampleStyleSheet()
doc = SimpleDocTemplate('inventory.pdf', 
                        rightMargin=0, leftMargin=0, topMargin=0, bottomMargin=0)

def createPageHeader():
    elements.append(Spacer(1, 10))
    elements.append(Image('car_logo.png', 100, 25))
    elements.append(Paragraph("Inventory", styles['Title']))
    elements.append(Spacer(1, 8))

def paginateInventory(start, stop):
    tbl = Table(df_data[0:1] + pg_data[start:stop])  
    tbl.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), '#F5F5F5'),
                             ('FONTSIZE', (0, 0), (-1, 0), 8),
                             ('GRID', (0, 0), (-1, -1), .5, '#a7a5a5')])) 
    elements.append(tbl)

def generatePDF():
    cur_pg = 0
    start_pos = 0
    stop_pos = recs_pg

    for cur_pg in range(tot_pgs):
        createPageHeader()
        paginateInventory(start_pos, stop_pos)
        elements.append(PageBreak())
        start_pos += recs_pg
        stop_pos += recs_pg
    doc.build(elements)

generatePDF()