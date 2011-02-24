require 'rubygems'
require 'zlib'
require 'net/http'
require 'stringio'
require 'cgi'
require 'libxml'
require 'nokogiri'
require 'tree'
require 'nesstar-api/catalog'
require 'nesstar-api/category'
require 'nesstar-api/category_statistic'
require 'nesstar-api/study'
require 'nesstar-api/study_date'
require 'nesstar-api/variable'
require 'nesstar-api/summary_stat'

module Nesstar
  module Api
    
    class CatalogApi
      
      #given tree of datasets and catalogs figure out which are the
      #survey types, which are surveys and link them to child datasets
      def parse_surveys_from_nodes node, surveys_hash, survey_types_hash
        node.children.each do |node|
          if node.name.index('fStudy')
            #this is a dataset, find its survey and survey_type
            survey = node.parent
            if surveys_hash.has_key?(survey.name)
              surveys_hash[survey.name].push(node.name)
            else
              surveys_hash[survey.name] = []
              surveys_hash[survey.name].push(node.name)
            end
            survey_type = survey.parent
            if survey_type
              if survey_types_hash.has_key?(survey_type.name)
                if !survey_types_hash[survey_type.name].include?(survey.name)
                  survey_types_hash[survey_type.name].push(survey.name)
                end
              else
                survey_types_hash[survey_type.name] = []
                survey_types_hash[survey_type.name].push(survey.name)
              end
            else
              if survey_types_hash.has_key?('none')
                if !survey_types_hash['none'].include?(survey.name)
                  survey_types_hash['none'].push(survey.name)
                end
              else
                survey_types_hash['none'] = []
                survey_types_hash['none'].push(survey.name)
              end
            end
          else
              #its a catalog so keep going downwards
              parse_surveys_from_nodes node, surveys_hash, survey_types_hash
          end
        end
      end

      def get_catalog url, catalog
        
        #Hash of catalogs to their child datasets
        catalog_hash = Hash.new
        
        uri = URI.parse(url)
        query_string = '/browser/browser?action=LIST&path=ROOT' + CGI.escape('|Properties|children') + "&url=" + CGI.escape('http://') + CGI.escape(uri.host + ':' + uri.port.to_s) + CGI.escape("/obj/fCatalog/" + catalog + "@children")
        full_uri = uri.merge query_string
        res = Net::HTTP.get full_uri
        doc = Nokogiri::HTML(res)
        
        parse_out_datasets doc, uri.host, catalog, catalog_hash

        return catalog_hash
      end
      
      def get_nodes url, catalog
        #tree of catalogs to their child datasets
        root_tree_node = Tree::TreeNode.new(catalog, "Catalog Content")
        
        uri = URI.parse(url)
        query_string = '/browser/browser?action=LIST&path=ROOT' + CGI.escape('|Properties|children') + "&url=" + CGI.escape('http://') + CGI.escape(uri.host + ':' + uri.port.to_s) + CGI.escape("/obj/fCatalog/" + catalog + "@children")
        full_uri = uri.merge query_string
        res = Net::HTTP.get full_uri
        doc = Nokogiri::HTML(res)
        
        dataset_tree doc, uri.host, catalog, root_tree_node
        
        return root_tree_node
      end
      
      #get the ddi xml for a nesstar dataset
      def get_ddi uri, dataset
        ddi_uri = URI.parse(uri)
        ddi_uri.merge!("/obj/fStudy/" + dataset)
        ddi_uri.merge!('?http://www.nesstar.org/rdf/method=http://www.nesstar.org/rdf/Dataset/GetDDI')
        res = Net::HTTP.get(ddi_uri)
        gz = Zlib::GzipReader.new(StringIO.new(res))
        xml = gz.read
        return xml
      end
      
      #return a catalog object with information inside it
      #uri is something like http://nesstar.here.com
      #catalog is the name of the catalog eg Catalog20
      def get_catalog_information uri, catalog
        catalog_uri = URI.parse(uri)
        catalog_uri.merge!("/obj/fCatalog/" + catalog)
        catalog_res = Net::HTTP.get(catalog_uri)
        gz = Zlib::GzipReader.new(StringIO.new(catalog_res))
        catalog_info = gz.read
        doc = Nokogiri::XML(catalog_info)
        label = doc.xpath('//s:label')
        description = doc.xpath('//s:comment')
        catalog = Nesstar::Catalog.new
        catalog.label = label[0].content.strip unless label[0] == nil
        catalog.description = description[0].content.strip unless description[0] == nil
        return catalog
      end
      
      #information about the dataset only
      def get_simple_study_information uri, dataset
        dataset_uri = URI.parse(uri)
        dataset_uri.merge!("/obj/fStudy/" + dataset)
        dataset_res = Net::HTTP.get(dataset_uri)
        gz = Zlib::GzipReader.new(StringIO.new(dataset_res))
        dataset_info = gz.read
        doc = Nokogiri::XML(dataset_info)
        label = doc.xpath('//s:label')
        description = doc.xpath('//s:comment')
        study = Nesstar::Study.new
        study.title = label[0].content.strip unless label[0] == nil
        study.abstract = description[0].content.strip unless description[0] == nil
        return study
      end
      
      #information about the dataset and its variables
      #inputs are the uri to a dataset file
      def get_study_information uri, dataset
        #TODO use the get_ddi method above
        ddi_uri = URI.parse(uri)
        ddi_uri.merge!("/obj/fStudy/" + dataset)
        ddi_uri.merge!('?http://www.nesstar.org/rdf/method=http://www.nesstar.org/rdf/Dataset/GetDDI')
        res = Net::HTTP.get(ddi_uri)
        gz = Zlib::GzipReader.new(StringIO.new(res))
        xml = gz.read
        catalog = Nesstar::Catalog.new
        study = Nesstar::Study.new
        study_info_hash = Hash.new
        parser = LibXML::XML::Parser.string(xml)
        doc = parser.parse
        studynodes = doc.find('//stdyDscr')
        abstracts = studynodes[0].find('//abstract')
        abstract = ""
        abstracts.each do |ab|
          abstract << ab.first.content.strip
        end
        study.abstract = abstract
        study.title = studynodes[0].find('//stdyDscr/citation/titlStmt/titl')[0].first.content.strip
        study.id = studynodes[0].find('//IDNo')[0].first.content.strip
        
        #start and finish dates for study
        dates = []
        date = studynodes[0].find('//sumDscr/collDate')
        date.each do |d|
          a = d.attributes
          study_date = Nesstar::StudyDate.new
          study_date.type = a.get_attribute('event').value.strip
          study_date.date = a.get_attribute('date').value.strip
          dates.push(study_date)
        end
        study.dates = dates
        study.sampling_procedure = studynodes[0].find('//sampProc')[0].first.content.strip unless studynodes[0].find('//sampProc')[0] == nil
        # study.weight = studynodes[0].find('//sampProc')[0].first.content
        study.variables = get_variable_information doc
        return study
      end

      def get_children

      end

      def add_dataset

      end
      
      private
      
      #pull out all the datasets for a catalog, recursively if need be
      def dataset_tree doc, uri, catalog, tree_node
        # if tree_node == nil
        #   tree_node = Tree::TreeNode.new(catalog, "Catalog Content")
        # end
        links = doc.xpath('//a')
        links.each do |link|
          if link.content.index(uri) != nil && link.content.index(catalog) == nil && link.content.index('fCatalog') == nil
            #its a dataset
            child_node = Tree::TreeNode.new(link.content,  catalog + " child")
            tree_node << child_node
          elsif link.content.index('fCatalog') != nil && link.content.index(catalog) == nil
            #its a new catalog
            url = URI.parse(link.content)
            new_catalog = url.path.split('/').last
            catalog_doc = retrieve_html "http://" + url.host + ':' + url.port.to_s, new_catalog
            child_node = Tree::TreeNode.new(link.content,  catalog + " child")
            tree_node << child_node
            dataset_tree catalog_doc, url.host, new_catalog, child_node
          end
        end
        return tree_node
      end

      #pull out all the datasets for a catalog, recursively if need be
      def parse_out_datasets doc, uri, catalog, catalog_hash
        if catalog_hash[catalog] == nil
          catalog_hash[catalog] = []
        end
        links = doc.xpath('//a')
        links.each do |link|
          if link.content.index(uri) != nil && link.content.index(catalog) == nil && link.content.index('fCatalog') == nil
            #its a dataset
            catalog_hash[catalog].push(link.content)
          elsif link.content.index('fCatalog') != nil && link.content.index(catalog) == nil
            #its a new catalog
            url = URI.parse(link.content)
            new_catalog = url.path.split('/').last
            catalog_doc = retrieve_html "http://" + url.host + ':' + url.port.to_s, new_catalog
            parse_out_datasets catalog_doc, url.host, new_catalog, catalog_hash
          end
        end
        return catalog_hash
      end
      
      def retrieve_html url, catalog
        uri = URI.parse(url)
        query_string = '/browser/browser?action=LIST&path=ROOT' + CGI.escape('|Properties|children') + "&url=" + CGI.escape('http://') + CGI.escape(uri.host + ':' + uri.port.to_s) + CGI.escape("/obj/fCatalog/" + catalog + "@children")
        full_uri = uri.merge query_string
        res = Net::HTTP.get full_uri
        doc = Nokogiri::HTML(res)
        return doc
      end
      
      #information about the variables
      def get_variable_information doc
        variables = []
        variable_info_hash = Hash.new
        docnodes = doc.find('//dataDscr')
        vargroups = docnodes[0].find('//dataDscr/varGrp')
        vargroups.each do |vargroup|
          #hash which holds all the variable groups
          a = vargroup.attributes
          groups = a.get_attribute('var')
          if groups != nil
            groups = a.get_attribute('var')
            variable_info_hash[vargroup.find('./labl')[0].first.content] = groups.value.split(' ')
          # else
          #             variable_info_hash[vargroup.find('./labl')[0].first.content] = groups.value.split(' ')
          end
        end
        vars = docnodes[0].find('//dataDscr/var')
        vars.each do |var|
          variable = Nesstar::Variable.new
          var_attr = var.attributes
          variable.id = var_attr.get_attribute('ID').value.strip unless var_attr.get_attribute('ID') == nil
          variable.name = var_attr.get_attribute('name').value.strip unless var_attr.get_attribute('name') == nil
          variable.file = var_attr.get_attribute('files').value.strip unless var_attr.get_attribute('files') == nil
          variable.interval = var_attr.get_attribute('intrvl').value.strip unless var_attr.get_attribute('intrvl') == nil
          variable.label = var.find('./labl')[0].content.strip unless var.find('./labl')[0] == nil 
          rng = var.find('./valrng')
          if rng != nil
            if rng[0] != nil
              range_attr = rng[0].first.attributes
              max_val = range_attr.get_attribute('max')
              variable.max = max_val.value.strip unless max_val == nil
              min_val = range_attr.get_attribute('min')
              variable.min = min_val.value.strip unless min_val == nil
            end
          end
          q = var.find('./qstn')
          if q[0] != nil
            ql = q[0].find('./qstnLit')
            if ql != nil
              if ql[0] != nil
                variable.question = ql[0].first.content.strip
              end
            end
            iv = q[0].find('./ivuInstr')
            if iv != nil
              if iv[0] != nil
                variable.interview_instruction = iv[0].first.content.strip
              end
            end
          end
          stats = var.find('./sumStat')
          summary_stats = []
          stats.each do |stat|
            a = stat.attributes
            # summary_stats[a.get_attribute('type').value] = stat.first.content
            statistic = Nesstar::SummaryStat.new
            statistic.type = a.get_attribute('type').value.strip
            statistic.value = stat.first.content.strip
            summary_stats.push(statistic)
          end
          variable.summary_stats = summary_stats
          catgry = var.find('./catgry')
          categories = []
          #categories in ddi are value domains in mb
          catgry.each do |cat|
            category = Nesstar::Category.new
            category.value = cat.find('./catValu').first.content
            labxml = cat.find('./labl')
            if labxml != nil && labxml[0] != nil
              category.label = labxml[0].first.content.strip unless labxml[0].first == nil
            end
            catstat = cat.find('./catStat')
            category_statistics = []
            catstat.each do |cat|
              category_statistic = Nesstar::CategoryStatistic.new
              a = cat.first.attributes unless cat.first == nil
              if a != nil
                category_statistic.type = a.get_attribute('type').strip unless a.get_attribute('type') == nil
                category_statistic.value = catstat.first.content.strip unless catstat.first == nil
                category_statistic.type = a.get_attribute('type').strip unless a.get_attribute('type') == nil
                category_statistics.push(category_statistic)
              end
            end
            category.category_statistics = category_statistics
            categories.push(category_statistics)
          end
          #what group is the variable in
          variable_info_hash.each_key do |key|
            if variable_info_hash[key].include?(variable.id)
              variable.group = key.strip
              break
            end
          end
          
          variable.categories = categories
          variables.push(variable)
        end
        return variables
      end
      
    end
  end
end
