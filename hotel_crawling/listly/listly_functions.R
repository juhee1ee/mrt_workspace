#############################
#     Listly Functions      #
#############################
library(readr)
library(httr)
library(rvest)
library(openssl)
library(stringr)
library(RCurl)
library(DBI)
library(data.table)
library(dplyr)
library(lubridate)

# Login Function
loginListly <- function(web_pg) {

  listly_url <- "https://www.listly.io/login/"
  user_info <- fread("/home/juheelee/R/hotel/domestic/user_info.csv")
  
  listly_info <- user_info %>% filter(type == web_pg)
  
  # Login to Listly
  remDr$navigate(listly_url)
  # Type Login Information
  remDr$findElement("xpath", '//*[@id="email"]')$sendKeysToElement(list(listly_info$id)) 
  remDr$findElement("xpath", '//*[@id="password"]')$sendKeysToElement(list(listly_info$password))
  
  # Click Login
  remDr$findElement("xpath", '//*[@id="login_form"]/div[3]/button')$clickElement()
  Sys.sleep(2)
  print(paste0("1. Log in completed"))
}

navigateGroup <- function(group_key) {
  # listly URL
  listly_page <- paste0("https://www.listly.io/group?key=", group_key,"&rows=1000&status=all&matched=all")
  remDr$navigate(listly_page)
}

navigateDashboard<- function() {
  # listly URL
  listly_page <- "https://www.listly.io/databoard#"
  remDr$navigate(listly_page)
}

removeAllListly <- function() {
  # select all & remove
  remDr$findElement("xpath", '/html/body/div[1]/div/div[5]/div/div/div[3]/div[2]/div[2]/table/thead/tr/th[1]/div[1]/input')$clickElement()
  
  Sys.sleep(2)
  # Remove 
  remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/button[1]')$clickElement()
  Sys.sleep(2)
  
  remDr$findElement("xpath", '//*[@id="remove_btn"]')$clickElement()
  Sys.sleep(3)
  
  print(paste0("2. Removed all URLs"))
  
}

uploadListly <- function(url_list_string) {
  # Update New URLs
  remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/div[1]/a')$clickElement()
  Sys.sleep(2)
  # Upload URL
  remDr$findElement("xpath", '/html/body/div/div/div[2]/div/div/form/div/div[1]/textarea')$sendKeysToElement(list(url_list_string))  #//*[@id="urls"]
  Sys.sleep(4)
  remDr$findElement("xpath", '//*[@id="group_btn"]')$clickElement()
  # print(paste0("3. Updated new URLs"))
}

refreshListly <- function() {
  # select all & crawling again
  remDr$findElement("xpath", '//*[@id="demo-custom-toolbar"]/thead/tr/th[1]/div[1]/input')$clickElement()
  Sys.sleep(2)
  # crawling again
  remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/button[2]')$clickElement()
  print(paste0("2. Selected All URLs"))
  Sys.sleep(3)
  remDr$findElement("xpath", '//*[@id="refresh_btn"]')$clickElement()
  Sys.sleep(2)
  print(paste0("3. Refresh button clicked"))
}

concurrChange <- function() {
  remDr$findElement("xpath", '/html/body/div/div/div[1]/div[2]/a/div')$clickElement()

  # Not working
  new_attr <- "setAttribute('style', 'left: 25%')"
  
  remDr$findElement("xpath", '/html/body/div[1]/div/div[1]/div[1]/div/div[2]/div/div/div[2]/div/div/span/span[1]/span[6]')$sendKeysToElement(list(new_attr))
  remDr$findElement("xpath", '/html/body/div[1]/div/div[1]/div[1]/div/div[2]/div/div/div[2]/div/div/span/span[1]/span[6]')$clickElement()
  Sys.sleep(0.5)
  remDr$findElement("xpath", '//*[@id="limit_edit_button"]')$clickElement()
  print(paste0("3. Change Concurrent URLs"))
}

reRunListly <- function() {
  listly_urls <- remDr$getPageSource()
  listly_html <- read_html(listly_urls[[1]])
  
  listly_table <- listly_html %>% html_nodes("div.fixed-table-body") %>% html_table()
  listly_table <- as.data.frame(listly_table[[1]])
  colnames(listly_table) <- c("check", "updated_at", "url", "status", "tab_matching", "screen_shot", "result")
  
  # Find status failed & re-run 
  listly_table <- listly_table %>% mutate(rank = row_number())
  listly_failed <- listly_table %>% filter(status == "Fail")
  
  if(nrow(listly_failed) != 0) {
    Sys.sleep(2)
    for(i in 1:nrow(listly_failed)) {
      remDr$findElement("xpath", paste0('//*[@id="demo-custom-toolbar"]/tbody/tr[', listly_failed$rank[i], ']/td[1]/input'))$clickElement()
    }
    
    # Re-run crawling
    remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/button[2]/span')$clickElement()
    Sys.sleep(2)
    remDr$findElement("xpath", '//*[@id="refresh_btn"]')$clickElement()
    
    print(paste0("2. Re-Run completed"))  
  } else {
    print(paste0("2. Nothing to Refresh"))    
  }
}

getListlyData <- function(key, url) {
  data_key <- GET(url, config = add_headers("Authorization" = key))
  result <- content(data_key)
  result_table <- fread(result)
  result_table <- as.data.frame(result_table)
  return(result_table)
}

manipulateListly <- function(result_table) {
  if(ncol(result_table) >= 7) {
    result_table1 <- result_table[, -c(7:ncol(result_table))]  
  } else {
    result_table1 <- result_table
  }
  colnames(result_table1) <- c("datakey", "url", "image", "company_name", "price", "price_unit")
  
  result_table1 <- unique(result_table1)
  missing <- result_table1 %>% filter(price == "")
  col_num <- ncol(result_table)
  col_num2 <- col_num-1
  
  missing_tbl <- result_table[, c(1:4, col_num2, col_num)]
  colnames(missing_tbl) <- c("datakey", "url", "image", "company_name", "price", "price_unit")
  missing_tbl <- missing_tbl %>% filter(datakey %in% unique(missing$datakey))
  
  result_table1 <- result_table1 %>% filter(price != "")
  result_all <- unique(rbind(result_table1, missing_tbl))
  
  result_all <- result_all %>% filter(company_name != "")
  result_all <- result_all %>% filter(price != "")
  
  return(result_all)
}

getBillingInfo <- function() {
  url <- "https://www.listly.io/billing"
  remDr$navigate(url)
  billing_url <- remDr$getPageSource()
  bill_html <- read_html(billing_url[[1]])
  curr_urls <- bill_html %>% html_nodes(xpath = "/html/body/div[1]/div/div[2]/div/div/div/div[2]/div/div/div[2]/h1/b") %>% 
    html_text()
  return(curr_urls)
}
