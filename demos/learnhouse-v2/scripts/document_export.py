from pathlib import Path
import io
import subprocess
import shutil
import zipfile
from lxml import etree as E
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'deliverables/assets'
WNS='http://schemas.openxmlformats.org/wordprocessingml/2006/main'; W='{'+WNS+'}'
def child(p,n):
    x=p.find(W+n)
    if x is None:x=E.SubElement(p,W+n)
    return x
def attr(e,**kw):
    for k,v in kw.items():e.set(W+k,str(v))
def xml(e):return E.tostring(e,encoding='UTF-8',xml_declaration=True,standalone=True)
def font(p,size=21,color=None):
    attr(child(p,'rFonts'),ascii='Calibri',hAnsi='Calibri',eastAsia='Noto Sans CJK SC');attr(child(p,'sz'),val=size)
    if color:attr(child(p,'color'),val=color)


def export_doc(source,title):
    pandoc=shutil.which('pandoc') or '/home/hongjian/anaconda3/bin/pandoc'
    raw=subprocess.check_output([pandoc,'--print-default-data-file','reference.docx'])
    with zipfile.ZipFile(io.BytesIO(raw)) as z:parts={n:z.read(n) for n in z.namelist()}
    styles=E.fromstring(parts['word/styles.xml'])
    for s in styles.findall(W+'style'):
        sid=s.get(W+'styleId');sz={'Title':34,'Subtitle':24,'Heading1':27,'Heading2':24,'Heading3':22}.get(sid,21)
        font(child(s,'rPr'),sz,'173F60' if sid.startswith('Heading') else None)
        pp=child(s,'pPr');attr(child(pp,'spacing'),after=100,line=280,lineRule='auto')
        if sid.startswith('Heading'):child(pp,'keepNext')
    parts['word/styles.xml']=xml(styles)
    reference=A/'reference.docx'
    with zipfile.ZipFile(reference,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)
    output=source.with_suffix('.docx')
    subprocess.run([pandoc,str(source),'-o',str(output),'--reference-doc',str(reference),'--resource-path',str(source.parent),'--metadata','lang=zh-CN'],check=True)
    with zipfile.ZipFile(output) as z:parts={n:z.read(n) for n in z.namelist()}
    doc=E.fromstring(parts['word/document.xml'])
    for s in doc.iter(W+'sectPr'):
        attr(child(s,'pgSz'),w=11906,h=16838);attr(child(s,'pgMar'),top=980,bottom=980,left=980,right=980,header=400,footer=400)
        footer=child(s,'footerReference');attr(footer,type='default')
        footer.set('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id','rIdPhaseFooter')
    for tb in doc.iter(W+'tbl'):
        rows=tb.findall(W+'tr');cols=len(rows[0].findall(W+'tc'));ratios={2:[28,72],3:[29,49,22],4:[20,40,25,15]}.get(cols,[100/cols]*cols)
        if cols==4 and '通过' in ''.join(rows[0].itertext()):ratios=[28,10,10,52]
        widths=[int(9946*r/100) for r in ratios];widths[-1]+=9946-sum(widths)
        pr=child(tb,'tblPr');attr(child(pr,'tblW'),w=9946,type='dxa');attr(child(pr,'tblLayout'),type='fixed')
        grid=child(tb,'tblGrid')
        for c in list(grid):grid.remove(c)
        for w in widths:attr(E.SubElement(grid,W+'gridCol'),w=w)
        borders=child(pr,'tblBorders')
        for edge in ['top','bottom','left','right','insideH','insideV']:attr(child(borders,edge),val='single',sz=4,color='C7D5E1')
        for i,row in enumerate(rows):
            child(child(row,'trPr'),'cantSplit')
            if i==0:child(child(row,'trPr'),'tblHeader')
            for c,w in zip(row.findall(W+'tc'),widths):
                attr(child(child(c,'tcPr'),'tcW'),w=w,type='dxa')
                if i%2==0:attr(child(child(c,'tcPr'),'shd'),fill='E8F0F8' if i==0 else 'F4F7FA')
                for p in c.iter(W+'p'):attr(child(child(p,'pPr'),'spacing'),after=65,line=250,lineRule='auto')
                for r in c.iter(W+'r'):
                    font(child(r,'rPr'),18)
                    if i==0:child(child(r,'rPr'),'b')
    parts['word/document.xml']=xml(doc)
    footer=E.Element(W+'ftr',nsmap={'w':WNS});p=E.SubElement(footer,W+'p');attr(child(child(p,'pPr'),'jc'),val='center')
    r=E.SubElement(p,W+'r');font(child(r,'rPr'),16,'617487');E.SubElement(r,W+'t').text='教育智能体 V2 · 2026-11-20  |  '
    fld=E.SubElement(p,W+'fldSimple');attr(fld,instr='PAGE');E.SubElement(E.SubElement(fld,W+'r'),W+'t').text='1'
    parts['word/footer-phase.xml']=xml(footer)
    rels=E.fromstring(parts['word/_rels/document.xml.rels']);rn='{http://schemas.openxmlformats.org/package/2006/relationships}'
    E.SubElement(rels,rn+'Relationship',Id='rIdPhaseFooter',Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer',Target='footer-phase.xml')
    parts['word/_rels/document.xml.rels']=xml(rels)
    ct=E.fromstring(parts['[Content_Types].xml']);E.SubElement(ct,'{http://schemas.openxmlformats.org/package/2006/content-types}Override',PartName='/word/footer-phase.xml',ContentType='application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml')
    parts['[Content_Types].xml']=xml(ct)
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)
    print(output.relative_to(ROOT))
