library(readr)
library(httr)
library(rvest)
library(openssl)
library(stringr)
library(RCurl)
library(DBI)
library(RSelenium)
library(data.table)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(bigrquery)
library(gargle)
setwd("/home/juheelee/R/hotel/domestic")

# 각 상세 url
createURL_v2 <- function(base_url, hotel_name, checkin, checkout) {
  url <- paste0(base_url, hotel_name)
  #  url <- paste0(url, "&adultCnt=2") # Add adult filter
  url <- paste0(url, "&checkIn=", checkin, "&checkOut=", checkout) # Add check in & out
  url <- paste0(url, "&adultCnt=2&includeTax=true") # Add extra info : 성인2, 세금포함
  
  #url <- paste0(url, "&sortField=popularityKR&sortDirection=descending&includeTax=true") # Add extra info
  #url <- paste0(url, "&pageIndex=", index) # Add page 
  return(url)
}

# version1 : 리스트 첫페이지에서 20개 숙소 가져올 때
createURL <- function(base_url, hotel_name, checkin, checkout, index) {
  url <- paste0(base_url, hotel_name)
  url <- paste0(url, "&adultCnt=2") # Add adult filter
  url <- paste0(url, "&checkIn=", checkin, "&checkOut=", checkout) # Add check in & out
#  url <- paste0(url, "&adultCnt=2&includeTax=true") # Add extra info : 성인2, 세금포함
  
  url <- paste0(url, "&sortField=popularityKR&sortDirection=descending&includeTax=true") # Add extra info
  url <- paste0(url, "&pageIndex=", index) # Add page 
  return(url)
}

