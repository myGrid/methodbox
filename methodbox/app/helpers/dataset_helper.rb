module DatasetHelper
  
  def dataset_format_options
    ["Tab Separated","Comma Separated"]
  end
  
  def dataset_metadata_options
    ["CCSR", "Methodbox"]
  end
  
  def dataset_revision dataset
    select_nums = []
    if dataset.current_version > 1
      start = dataset.current_version - 1
    else
      start = 1
    end
    finish = dataset.current_version + 10
    (start..finish).each { |i| select_nums << i }
    return select_nums
  end
end