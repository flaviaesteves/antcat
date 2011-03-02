require 'spec_helper'

describe Bolton::SubfamilyCatalog do
  before do
    @subfamily_catalog = Bolton::SubfamilyCatalog.new
  end

  describe "Importing a list of files" do

    it "should process only files beginning with numbers, and them in numerical order" do
      File.should_receive(:read).with('data/bolton/01. FORMICIDAE.htm').ordered.and_return ''
      File.should_receive(:read).with('data/bolton/02. DOLICHODEROMORPHS.htm').ordered.and_return ''
      File.should_not_receive(:read).with('data/bolton/NGC-GEN.A-L.htm')
      @subfamily_catalog.import_files ['data/bolton/NGC-GEN.A-L.htm', 'data/bolton/02. DOLICHODEROMORPHS.htm', 'data/bolton/01. FORMICIDAE.htm']
    end

  end

  describe "Importing HTML" do
    def make_contents content
      %{<html><body><div class=Section1>#{content}</div></body></html>}
    end

    describe "Importing the catalog" do

      it "should parse the family, then the subfamilies" do
        @subfamily_catalog.should_receive(:parse_family).ordered
        @subfamily_catalog.should_receive(:parse_supersubfamilies).ordered
        @subfamily_catalog.import_html make_contents %{
    <p class=MsoNormal align=center style='text-align:center'><b style='mso-bidi-font-weight:
    normal'><span lang=EN-GB>FAMILY FORMICIDAE<o:p></o:p></span></b></p>
        }
      end

      it "should parse each part of the family section" do
        @subfamily_catalog.should_receive(:parse_family_summary).ordered.and_return true
        @subfamily_catalog.should_receive(:parse_genera_incertae_sedis_in_family).ordered.and_return true
        @subfamily_catalog.should_receive(:parse_genera_excluded_from_family).ordered.and_return true
        @subfamily_catalog.should_receive(:parse_unavailable_group_names).ordered.and_return true
        @subfamily_catalog.should_receive(:parse_genus_group_nomina_nuda).ordered.and_return true
        @subfamily_catalog.import_html make_contents %{
    <p class=MsoNormal align=center style='text-align:center'><b style='mso-bidi-font-weight:
    normal'><span lang=EN-GB>FAMILY FORMICIDAE<o:p></o:p></span></b></p>
        }
      end

      it "should parse the family summary section" do
        @subfamily_catalog.import_html make_contents %{
<p class=MsoNormal align=center style='text-align:center'><b style='mso-bidi-font-weight:
normal'><span lang=EN-GB>FAMILY FORMICIDAE<o:p></o:p></span></b></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamilies of
Formicidae (extant)</span></b><span lang=EN-GB>: Aenictinae, Myrmicinae<b style='mso-bidi-font-weight: normal'>.</b></span></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamilies of
Formicidae (extinct)</span></b><span lang=EN-GB>: *Armaniinae, *Brownimeciinae.</span></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera
(extant) <i style='mso-bidi-font-style:normal'>incertae sedis</i> in Formicidae</span></b><span
lang=EN-GB>: <i style='mso-bidi-font-style:normal'>Condylodon</i>.</span></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera
(extinct) <i style='mso-bidi-font-style:normal'>incertae sedis</i> in
Formicidae</span></b><span lang=EN-GB>: <i style='mso-bidi-font-style:normal'>*Calyptites</i>.</span></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera
(extant) excluded from Formicidae</span></b><span lang=EN-GB>: <i
style='mso-bidi-font-style:normal'><span style='color:green'>Formila</span></i>.</span></p>

<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera
(extinct) excluded from Formicidae</span></b><span lang=EN-GB>: *<i
style='mso-bidi-font-style:normal'><span style='color:green'>Cariridris</span></i>.</span></p>
        }
        taxon = Subfamily.find_by_name 'Aenictinae'
        taxon.should_not be_invalid
        taxon.should_not be_fossil
        taxon = Subfamily.find_by_name 'Myrmicinae'
        taxon.should_not be_invalid
        taxon.should_not be_fossil

        taxon = Subfamily.find_by_name 'Armaniinae'
        taxon.should_not be_invalid
        taxon.should be_fossil
        taxon = Subfamily.find_by_name 'Brownimeciinae'
        taxon.should_not be_invalid
        taxon.should be_fossil

        taxon = Genus.find_by_name 'Condylodon'
        taxon.should_not be_invalid
        taxon.should_not be_fossil
        taxon.incertae_sedis_in.should == 'family'

        taxon = Genus.find_by_name 'Calyptites'
        taxon.should_not be_invalid
        taxon.should be_fossil
        taxon.incertae_sedis_in.should == 'family'

        taxon = Genus.find_by_name 'Formila'
        taxon.should be_invalid
        taxon.should_not be_fossil
        taxon.status.should == 'excluded'

        taxon = Genus.find_by_name 'Cariridris'
        taxon.should be_invalid
        taxon.should be_fossil
        taxon.status.should == 'excluded'

      end

    end
  end


  #describe "Importing a file" do
    #it "should import incertae sedis in Formicidae" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='text-align:justify'><b style='mso-bidi-font-weight:
#normal'><span lang=EN-GB>Genera <i style='mso-bidi-font-style:normal'>incertae
#sedis</i> in <span style='color:red'>FORMICIDAE</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='text-align:justify'><span lang=EN-GB><o:p>&nbsp;</o:p></span></p>

#<p class=MsoNormal style='text-align:justify'><b style='mso-bidi-font-weight:
#normal'><span lang=EN-GB>Genus</span></b><span lang=EN-GB> *<b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#style='color:red'>CALYPTITES</span></i></b> </span></p>
      #}
      #Genus.find_by_name('Calyptites').incertae_sedis_in.should == 'family'
    #end

    #it "should import incertae sedis in a subfamily" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-top:0cm;margin-right:-1.25pt;margin-bottom:
#0cm;margin-left:36.0pt;margin-bottom:.0001pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily <span
#style='color:red'>ANEURETINAE</span> <o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera <i
#style='mso-bidi-font-style:normal'>incertae sedis</i> in <span
#style='color:red'>ANEURETINAE</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><span
#lang=EN-GB><o:p>&nbsp;</o:p></span></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus *<i
#style='mso-bidi-font-style:normal'><span style='color:red'>BURMOMYRMA</span></i>
#<o:p></o:p></span></b></p>
      #}
      #burmomyrma = Genus.find_by_name('Burmomyrma')
      #burmomyrma.incertae_sedis_in.should == 'subfamily'
      #burmomyrma.tribe.should be_nil
      #burmomyrma.subfamily.name.should == 'Aneuretinae'
    #end

    #it 'should add subfamilies and genera when it sees them' do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-top:0in;margin-right:-1.25pt;margin-bottom:
#0in;margin-left:.5in;margin-bottom:.0001pt;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily <span
#style='color:red'>CERAPACHYINAE</span> <o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Myrmeciidae</span></b><span
#lang=EN-GB> Emery, 1877a: 71. Type-genus: <i style='mso-bidi-font-style:normal'>Myrmecia</i>.</span></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><span
#lang=EN-GB><o:p>&nbsp;</o:p></span></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Myrmeciidae</span></b><span
#lang=EN-GB> Emery, 1877a: 71. Type-genus: <i style='mso-bidi-font-style:normal'>Myrmecia</i>.</span></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i style='mso-bidi-font-style:
#normal'><span style='color:red'>ATTA</span></i> <o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#lang=EN-GB>Atta</span></i></b><span lang=EN-GB> Fabricius, 1804: 421.
#Type-species: <i style='mso-bidi-font-style:normal'>Formica cephalotes</i>, by
#subsequent designation of Wheeler, W.M. 1911f: 159. </span></p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily *<span
#style='color:red'>ARMANIINAE</span> <o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus *<i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANEURETELLUS</span></i>
#<o:p></o:p></span></b></p>
      #}

      #Subfamily.find_by_name('Myrmicinae').should_not be_nil

      #aneuretellus = Genus.find_by_name('Aneuretellus')
      #aneuretellus.should_not be_nil
      #aneuretellus.should be_fossil
      #aneuretellus.subfamily.name.should == 'Armaniinae'
      #aneuretellus.status.should be_nil

      #armaniinae = Subfamily.find_by_name('Armaniinae')
      #armaniinae.should_not be_nil
      #armaniinae.should be_fossil
      #armaniinae.status.should be_nil

      #cerapachyinae = Subfamily.find_by_name 'Cerapachyinae'
      #cerapachyinae.should_not be_nil
      #cerapachyinae.taxonomic_history.should == 
#%{<p class=\"MsoNormal\" style=\"margin-left:.5in;text-align:justify;text-indent:-.5in\"><b style=\"mso-bidi-font-weight:normal\"><span lang=\"EN-GB\">Myrmeciidae</span></b><span lang=\"EN-GB\"> Emery, 1877a: 71. Type-genus: <i style=\"mso-bidi-font-style:normal\">Myrmecia</i>.</span></p><p class=\"MsoNormal\" style=\"margin-left:.5in;text-align:justify;text-indent:-.5in\"><span lang=\"EN-GB\"><p> </p></span></p>}

      #atta = Genus.find_by_name 'Atta'
      #atta.should_not be_nil
      #atta.tribe.name.should == 'Myrmeciini'
      #atta.tribe.subfamily.should == cerapachyinae
      #atta.tribe.status.should be_nil
      #atta.subfamily.status.should be_nil
      #atta.status.should be_nil
      #atta.taxonomic_history.should == 
#%{<p class="MsoNormal" style="margin-left:.5in;text-align:justify;text-indent:-.5in"><b style="mso-bidi-font-weight:normal"><i style="mso-bidi-font-style:normal"><span lang="EN-GB">Atta</span></i></b><span lang="EN-GB"> Fabricius, 1804: 421. Type-species: <i style="mso-bidi-font-style:normal">Formica cephalotes</i>, by subsequent designation of Wheeler, W.M. 1911f: 159. </span></p>}
    #end

    #it "should grab the full taxonomic history" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily <span
#style='color:red'>PROCERATIINAE</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Proceratii</span></b><span
#lang=EN-GB> Emery, 1895j: 765. Type-genus: <i style='mso-bidi-font-style:normal'>Proceratium</i>.
#</span></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Taxonomic
#history<o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><span lang=EN-GB>Proceratiinae as poneromorph subfamily of Formicidae:
#Bolton, 2003: 48, 178.</span></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><span lang=EN-GB>Proceratiinae as poneroid subfamily of Formicidae:
#Ouellette, Fisher, <i style='mso-bidi-font-style:normal'>et al</i>. 2006: 365;
#Brady, Schultz, <i style='mso-bidi-font-style:normal'>et al</i>. 2006: 18173;
#Moreau, Bell <i style='mso-bidi-font-style:normal'>et al</i>. 2006: 102; Ward,
#2007a: 555.</span></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><span lang=EN-GB>Tribes of Proceratiinae: Probolomyrmecini,
#Proceratiini.</span></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><span lang=EN-GB><o:p>&nbsp;</o:p></span></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily
#references<o:p></o:p></span></b></p>

#<p class=MsoNormal style='text-align:justify'><span lang=EN-GB>Bolton, 2003:
#48, 178 (diagnosis, synopsis); Ouellette, Fisher <i style='mso-bidi-font-style:
#normal'>et al</i>. 2006: 359 (phylogeny); Brady, Schultz, <i style='mso-bidi-font-style:
#normal'>et al</i>. 2006: 18173 (phylogeny); Moreau, Bell <i style='mso-bidi-font-style:
#normal'>et al</i>. 2006: 102 (phylogeny); Ward, 2007a: 555 (classification);
#Fernández &amp; Arias-Penna, 2008: 31 (Neotropical genera key); Yoshimura &amp;
#Fisher, 2009: 8 (Malagasy males diagnosis, key); Terayama, 2009: 96 (Taiwan
#genera key).</span></p>
      #}

      #Subfamily.find_by_name('Proceratiinae').taxonomic_history.should ==
#"<p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><b style=\"mso-bidi-font-weight:normal\"><span lang=\"EN-GB\">Proceratii</span></b><span lang=\"EN-GB\"> Emery, 1895j: 765. Type-genus: <i style=\"mso-bidi-font-style:normal\">Proceratium</i>. </span></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><b style=\"mso-bidi-font-weight:normal\"><span lang=\"EN-GB\">Taxonomic history<p></p></span></b></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><span lang=\"EN-GB\">Proceratiinae as poneromorph subfamily of Formicidae: Bolton, 2003: 48, 178.</span></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><span lang=\"EN-GB\">Proceratiinae as poneroid subfamily of Formicidae: Ouellette, Fisher, <i style=\"mso-bidi-font-style:normal\">et al</i>. 2006: 365; Brady, Schultz, <i style=\"mso-bidi-font-style:normal\">et al</i>. 2006: 18173; Moreau, Bell <i style=\"mso-bidi-font-style:normal\">et al</i>. 2006: 102; Ward, 2007a: 555.</span></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><span lang=\"EN-GB\">Tribes of Proceratiinae: Probolomyrmecini, Proceratiini.</span></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><span lang=\"EN-GB\"><p> </p></span></p><p class=\"MsoNormal\" style=\"margin-left:36.0pt;text-align:justify;text-indent: -36.0pt\"><b style=\"mso-bidi-font-weight:normal\"><span lang=\"EN-GB\">Subfamily references<p></p></span></b></p><p class=\"MsoNormal\" style=\"text-align:justify\"><span lang=\"EN-GB\">Bolton, 2003: 48, 178 (diagnosis, synopsis); Ouellette, Fisher <i style=\"mso-bidi-font-style: normal\">et al</i>. 2006: 359 (phylogeny); Brady, Schultz, <i style=\"mso-bidi-font-style: normal\">et al</i>. 2006: 18173 (phylogeny); Moreau, Bell <i style=\"mso-bidi-font-style: normal\">et al</i>. 2006: 102 (phylogeny); Ward, 2007a: 555 (classification); Fernández &amp; Arias-Penna, 2008: 31 (Neotropical genera key); Yoshimura &amp; Fisher, 2009: 8 (Malagasy males diagnosis, key); Terayama, 2009: 96 (Taiwan genera key).</span></p><p class=\"MsoNormal\" style=\"margin-left:.5in;text-align:justify;text-indent:-.5in\"><p> </p></p>"
    #end
      

    #it "should not include 'Genus incertae sedis in [...]' in the taxonomic history" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'>incertae sedis</i> in <span
#style='color:red'>Stenammini</span><o:p></o:p></span></b></p>
      #}
      #ancyridris = Genus.find_by_name 'Ancyridris'
      #ancyridris.taxonomic_history.should == ''
    #end

    #it "should not carry over the current tribe after seeing 'Genus incertae sedis in...'" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='text-align:justify'><b style='mso-bidi-font-weight:
#normal'><span lang=EN-GB>Genera <i style='mso-bidi-font-style:normal'>incertae
#sedis</i> in <span style='color:red'>FORMICINAE</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus *<i
#style='mso-bidi-font-style:normal'><span style='color:red'>CAMPONOTITES</span></i>
#<o:p></o:p></span></b></p>
      #}
      #camponotites = Genus.find_by_name 'Camponotites'
      #camponotites.tribe.should be_nil
    #end

    #it "should not include the subfamily header in the tazonomic history" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>

#<p class=MsoNormal align=center style='margin-top:0in;margin-right:-1.25pt;
#margin-bottom:0in;margin-left:.5in;margin-bottom:.0001pt;text-align:center;
#text-indent:-.5in;tab-stops:6.25in'><b style='mso-bidi-font-weight:normal'><span
#lang=EN-GB>SUBFAMILY <span style='color:red'>ECITONINAE</span><o:p></o:p></span></b></p>
      #}
      #ancyridris = Genus.find_by_name 'Ancyridris'
      #ancyridris.taxonomic_history.should == ''
    #end

    #it "should handle a plus sign in the taxonomic history" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>

#<p>Panama + Columbia</p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily <span
#style='color:red'>PROCERATIINAE</span><o:p></o:p></span></b></p>
      #}
      #ancyridris = Genus.find_by_name 'Ancyridris'
      #ancyridris.taxonomic_history.should == '<p>Panama + Columbia</p>'
    #end

    #it "should not translate &quot; character entity" do
      #@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>

#<p>&quot;XXX</p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamily <span
#style='color:red'>PROCERATIINAE</span><o:p></o:p></span></b></p>
      #}
      #ancyridris = Genus.find_by_name 'Ancyridris'
      #ancyridris.taxonomic_history.should == '<p>&quot;XXX</p>'
    #end

    #it "should complain if it sees the same subfamily twice" do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>
#<p>&quot;XXX</p>
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>
      #}}.should raise_error
    #end

    #it "should complain if it sees the same tribe twice" do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>
#<p>&quot;XXX</p>
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>
      #}}.should raise_error
    #end

    #it "should complain if it sees the same genus twice" do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>
#<p>&quot;XXX</p>
#<p class=MsoNormal style='margin-left:36.0pt;text-align:justify;text-indent:
#-36.0pt'><b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i
#style='mso-bidi-font-style:normal'><span style='color:red'>ANCYRIDRIS</span></i>
#<o:p></o:p></span></b></p>
      #}}.should raise_error
    #end

    #it 'should complain if adding a genus without a tribe' do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
#</p>

#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i style='mso-bidi-font-style:
#normal'><span style='color:red'>ATTA</span></i> <o:p></o:p></span></b></p>
      #}}.should raise_error "Genus Atta has no tribe"
    #end

    #it "should complain if adding a genus that's incertae_sedis in subfamily without a subfamily" do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genera <i
#style='mso-bidi-font-style:normal'>incertae sedis</i> in <span
#style='color:red'>ANEURETINAE</span><o:p></o:p></span></b></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><span
#lang=EN-GB><o:p>&nbsp;</o:p></span></p>

#<p class=MsoNormal style='margin-right:-1.25pt;text-align:justify'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus *<i
#style='mso-bidi-font-style:normal'><span style='color:red'>BURMOMYRMA</span></i>
#<o:p></o:p></span></b></p>
      #}}.should raise_error "Genus Burmomyrma is incertae sedis in subfamily with no subfamily"
    #end

    #it 'should complain if adding a genus without a subfamily' do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Genus <i style='mso-bidi-font-style:
#normal'><span style='color:red'>ATTA</span></i> <o:p></o:p></span></b></p>
      #}}.should raise_error "Genus Atta has no subfamily"
    #end

    #it 'should complain if adding a tribe without a subfamily' do
      #lambda {@subfamily_catalog.import_html make_contents %{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><span lang=EN-GB>Tribe <span
#style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>
      #}}.should raise_error "Tribe Myrmeciini has no subfamily"
    #end

  #end

  describe "Parsing a line" do

    it "should recognize the family header" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>FAMILY FORMICIDAE<o:p></o:p></span></b>
      }).should == {:type => :family_header}
    end

    it "should recognize the extant subfamilies section" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>Subfamilies of Formicidae (extant)</span></b><span lang=EN-GB>: Aenictinae, Myrmicinae<b>.</b></span></p> }).should == {:type => :extant_subfamilies, :subfamilies => ['Aenictinae', 'Myrmicinae']}
    end

    it "should recognize the extinct subfamilies section" do
      @subfamily_catalog.parse(%{
<b style='mso-bidi-font-weight:normal'><span lang=EN-GB>Subfamilies of Formicidae (extinct)</span></b><span lang=EN-GB>: *Armaniinae, *Brownimeciinae.</span>
}).should == {:type => :extinct_subfamilies, :subfamilies => ['Armaniinae', 'Brownimeciinae']}
    end

    it "should recognize the extant genera incertae sedis section" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>Genera (extant) <i>incertae sedis</i> in Formicidae</span></b><span lang=EN-GB>: <i>Condylodon</i>.</span></p>
}).should == {:type => :extant_genera_incertae_sedis_in_family, :genera => ['Condylodon']}
    end

    it "should recognize the extinct genera incertae sedis section" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>Genera (extinct) <i>incertae sedis</i> in Formicidae</span></b><span lang=EN-GB>: <i>*Condylodon</i>.</span></p>
}).should == {:type => :extinct_genera_incertae_sedis_in_family, :genera => ['Condylodon']}
    end

    it "should recognize the extant genera excluded from family" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>Genera (extant) excluded from Formicidae</span></b><span lang=EN-GB>: <i><span style='color:green'>Formila</span></i>.</span></p>
}).should == {:type => :extant_genera_excluded_from_family, :genera => ['Formila']}
    end

    it "should recognize the extinct genera excluded from family" do
      @subfamily_catalog.parse(%{
<b><span lang=EN-GB>Genera (extinct) excluded from Formicidae</span></b><span lang=EN-GB>: *<i><span style='color:green'>Cariridris, *Cretacoformica</span></i>.</span>
}).should == {:type => :extinct_genera_excluded_from_family, :genera => ['Cariridris', 'Cretacoformica']}
    end


      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Subfamily <span style='color:red'>MYRMICINAE</span> <o:p></o:p></span></b>
      #}).should == {:type => :subfamily, :name => 'Myrmicinae'}
    #end

    #it "should recognize an extinct subfamily line" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Subfamily *<span style='color:red'>ARMANIINAE</span> <o:p></o:p></span></b></p>
      #}).should == {:type => :subfamily, :name => 'Armaniinae', :fossil => true}
    #end

    #it "should recognize the beginning of a tribe" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Tribe <span style='color:red'>MYRMECIINI</span><o:p></o:p></span></b></p>
      #}).should == {:type => :tribe, :name => 'Myrmeciini'}
    #end

    #it "should recognize the beginning of a fossil tribe" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Tribe *<span style='color:red'>MIOMYRMECINI</span><o:p></o:p></span></b>
      #}).should == {:type => :tribe, :name => 'Miomyrmecini', :fossil => true}
    #end

    #it "should recognize the beginning of a genus" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genus <i><span style='color:red'>ATTA</span></i> <o:p></o:p></span></b></p>
      #}).should == {:type => :genus, :name => 'Atta'}
    #end

    #it "should recognize the beginning of a genus when the word 'Genus' is in italics, too" do
      #@subfamily_catalog.parse(%{
#<b><i><span lang=EN-GB style='color:black'>Genus</span><span lang=EN-GB style='color:red'> PARVIMYRMA</span></i></b>
      #}).should == {:type => :genus, :name => 'Parvimyrma'}
    #end

    #it "should recognize a fossil genus with an extra language span" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genus</span></b><span lang=EN-GB> *<b><i><span style='color:red'>CTENOBETHYLUS</span></i></b> </span>
      #}).should == {:type => :genus, :name => 'Ctenobethylus', :fossil => true}
    #end

    #it "should recognize the beginning of a fossil genus" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genus *<i><span style='color:red'>ANEURETELLUS</span></i> <o:p></o:p></span></b></p>
      #}).should == {:type => :genus, :name => 'Aneuretellus', :fossil => true}
    #end

    #it "should handle an empty span in there" do
      #@subfamily_catalog.parse(%{
#<b><span lang="EN-GB">Genus *<i><span style="color:red">EOAENICTITES</span></i></span></b><span lang="EN-GB"> </span>
      #}).should == {:type => :genus, :name => 'Eoaenictites', :fossil => true}
    #end

    #it "should recognize this tribe" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Tribe</span></b><span lang=EN-GB> *<b style='mso-bidi-font-weight:normal'><span style='color:red'>PITYOMYRMECINI</span></b></span>
      #}).should == {:type => :tribe, :name => 'Pityomyrmecini', :fossil => true}
    #end

    #it "should recognize an incertae sedis header in tribe" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genus <i>incertae sedis</i> in <span style='color:red'>Stenammini</i>
      #}).should == {:type => :incertae_sedis_in_tribe_header}
    #end

    #it "should recognize Hong's incertae sedises" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genera of Hong (2002), <i>incertae sedis</i> in <span style='color:red'>MYRMICINAE</span><o:p></o:p></span></b>
      #}).should == {:type => :incertae_sedis_in_subfamily_header}
    #end

    #it "should recognize incertae sedis in subfamily" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genera <i>incertae sedis</i> in <span style='color:red'>MYRMICINAE</span><o:p></o:p></span></b>
      #}).should == {:type => :incertae_sedis_in_subfamily_header}
    #end

    #it "should recognize extinct incertae sedis in subfamily" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>Genera (extinct) <i>incertae sedis</i> in <span style='color:red'>DOLICHODERINAE<o:p></o:p></span></span></b>
      #}).should == {:type => :incertae_sedis_in_subfamily_header}
    #end

    #it "should recognize a subfamily header" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>SUBFAMILY <span style='color:red'>ECITONINAE</span><o:p></o:p></span></b></p>
      #}).should == {:type => :subfamily_header}
    #end

    #it "should recognize another form of subfamily header" do
      #@subfamily_catalog.parse(%{
#<b><span lang="EN-GB" style="color:black">SUBFAMILY</span><span lang="EN-GB"> <span style="color:red">MARTIALINAE</span><p></p></span></b>
      #}).should == {:type => :subfamily_header}
    #end

    #it "should recognize the supersubfamily header" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>THE PONEROIDS: SUBFAMILIES AGROECOMYRMECINAE, AMBLYOPONINAE, PARAPONERINAE, PONERINAE AND PROCERATIINAE<o:p></o:p></span></b>
      #}).should == {:type => :supersubfamily_header}
    #end

    #it "should recognize the supersubfamily header when there's only one subfamily" do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB>THE MYRMICOMORPHS: SUBFAMILY MYRMICINAE<o:p></o:p></span></b></p>
      #}).should == {:type => :supersubfamily_header}
    #end

    #it 'should handle italics in weird place' do
      #@subfamily_catalog.parse(%{
#<b><span lang=EN-GB style='color:black'>Genus *</span><i><span lang=EN-GB style='color:red'>HAIDOMYRMODES</span></i><span lang=EN-GB><o:p></o:p></span></b>
      #}).should == {:type => :genus, :name => 'Haidomyrmodes', :fossil => true}
    #end

    #it "should handle it when the span is before the bold and there's a subfamily at the end" do
      #@subfamily_catalog.parse(%{
#<span lang=EN-GB>Genus *<b style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span style='color:red'>YPRESIOMYRMA</span></i></b> [Myrmeciinae]</span>
      #}).should == {:type => :genus, :name => 'Ypresiomyrma', :fossil => true}
    #end

  end
end

