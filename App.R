#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

#any packages we need to import can go here
library(dplyr)
library(plotly)
library(shiny)
library(shinyWidgets)
library(ggplot2)
library(shinyjs)
library(lubridate)
library(fpp3)
library(forecast)
library(fable)
library(ggfortify)
library(zoo)
library(xts)


temp1 <- read.csv("daily-temperature-for-30-sites-to-2022-part1.csv", fileEncoding = "UTF-8")
temp2 <- read.csv("daily-temperature-for-30-sites-to-2022-part2.csv", fileEncoding = "UTF-8")
temp3 <- read.csv("daily-temperature-for-30-sites-to-2022-part3.csv", fileEncoding = "UTF-8")

temp4 <- full_join(temp1, temp2)
temp <- full_join(temp4, temp3)

get_season <- function(date) {
  #convert date to a format that can be used for comparison
  md <- format(ymd(date), "%m-%d")
  
  case_when( #assign season to data depending on the date
    md >= "12-01" | md <= "02-28" ~ "Summer",
    md >= "03-01" & md <= "05-31" ~ "Autumn",
    md >= "06-01" & md <= "08-31" ~ "Winter",
    md >= "09-01" & md <= "11-30" ~ "Spring",
    TRUE ~ NA_character_
  )
}

#add season column to the dataset
temp <- temp %>%
  mutate(season = get_season(date),
         year = year(ymd(date)))  #adding a year column for time-based analysis

temp$date <- as.Date(temp$date) #convert date column to date object

temp <- temp %>%
  mutate(month = month(date))%>%
  mutate(month_year = format(as.Date(temp$date), "%Y-%m-01")) %>%
  mutate(month_year = as.Date(month_year))

temp <- temp %>% arrange(date) #sort data by date

#OPEN IN FULL SCREEN
#when you run this code it might say error instead of displaying the graph/plot, just wait a little bit and it should correct itself (you will need to wait a little bit when applying filters and switching tabs to another plot, they will all say an error at first but disappear after a few seconds and then the plot is displayed)



ui <- fluidPage(
  useShinyjs(), #use shinyJS to implement JavaScript for interactive and dynamic UI elements
  tags$head(
    tags$style(HTML("
      .plot-container {
        width: 100%;
        height: 800px;
        margin: auto;
      }
    "))
  ),
  titlePanel("Temperature Data Analysis"),
  
  #tabbed layout
  
  tabsetPanel(
    
             
             mainPanel(
               
               tags$h3("Background and Data"),
               tags$p("REPORT IN HERE"), #WRITE REPORT SECTION IN HERE
               tags$h3("Ethics and Privacy"),
               tags$p("REPORT IN HERE"), #WRITE REPORT SECTION IN HERE
               tags$h3("Exploratory Data Analysis")
             )
    ),
               
               
               
             
    
  tabsetPanel(
    tabPanel("Histogram/Density Plot",
             sidebarLayout(
               sidebarPanel(
                 #inputs
                 
                 #statistic selection
                 selectInput("statistic", "Select Statistic:", 
                             choices = unique(temp$statistic), selected = "Average"),
                 
                 #year selection
                 selectInput("year_type", "Select Year(s):",
                             choices = c("Individual Years", "Year Range"),
                             selected = "Year Range"),
                 
                 uiOutput("individual_year_ui"),
                 
                 uiOutput("year_range_ui"),
                 
                 #season selection
                 selectInput("season", "Select Season:",
                             choices = c("All", "Summer", "Autumn", "Winter", "Spring")),
                 
                 #histogram section label
                 h4("Histogram"),
                 
                 #histogram inputs
                 radioButtons("plot_type", "Plot Type:",
                              choices = c("Histogram" = "histogram", "Density Plot" = "density")),
                 
                 #overlay density plot checkbox and help text
                 tagList(
                   checkboxInput("overlay", "Overlay Density Plot on Histogram", value = FALSE),
                   helpText("Note: Histogram must be selected as the plot type for the density overlay to work.")
                 ),
                 
                 sliderInput("binwidth", "Bin Width:", min = 1, max = 5, value = 1),
                 selectInput("site", "Select Site:", choices = c("All Sites", unique(temp$site)))
               ),
               mainPanel(
                 
                 div(class = "plot-container",
                     plotlyOutput("distPlot", height = "100%")
                 ),
                 tags$div(
                   tags$h3("Histogram and Density Plot Analysis"),
                   tags$p("REPORT IN HERE") #WRITE REPORT SECTION IN HERE
                 ),
               )
             )),
    
    tabPanel("Boxplot",
         sidebarLayout(
           sidebarPanel(
             #boxplot section label
             h4("Boxplot"),
             
             #statistic selection
             selectInput("box_statistic", "Select Statistic:", 
                         choices = unique(temp$statistic), selected = "Average"),
             
             #year selection
             selectInput("box_year_type", "Select Year(s):",
                         choices = c("Individual Years", "Year Range"),
                         selected = "Year Range"),
             
             
             uiOutput("box_individual_year_ui"),
             uiOutput("box_year_range_ui"),
             helpText("Note: Please select a year from the list above when doing individual years"),
             
             
             
             #season selection
             selectInput("box_season", "Select Season:",
                         choices = c("All", "Summer", "Autumn", "Winter", "Spring")),
             
             #boxplot inputs
             selectInput("comparison_type", "Comparison Type:",
                         choices = c("All Sites" = "all", "Compare Sites" = "compare")),
             uiOutput("comparison_sites_ui"),
             uiOutput("add_site_ui")  #dynamic UI for add site button
           ),
           mainPanel(
             div(class = "plot-container",
                 plotlyOutput("boxPlot", height = "100%")
             ),
             tags$div(
               tags$h3("Boxplot Analysis"),
               tags$p("REPORT IN HERE") #WRITE REPORT IN THIS SECTION
             )
           )
         )),
    
    tabPanel("Correlation Matrix",
             sidebarLayout(
               sidebarPanel(
                 h4("Correlation Matrix"),
                 
                 #statistic selection
                 selectInput("cor_statistic", "Select Statistic:", 
                             choices = unique(temp$statistic), selected = "Average"),
                 
                 #year selection
                 selectInput("cor_year_type", "Select Year(s):",
                             choices = c("Individual Years", "Year Range"),
                             selected = "Year Range"),
                 
                 uiOutput("cor_individual_year_ui"),
                 
                 uiOutput("cor_year_range_ui"),
                 
                 #season selection
                 selectInput("cor_season", "Select Season:",
                             choices = c("All", "Summer", "Autumn", "Winter", "Spring")),
                 
                 #correlation method selection
                 radioButtons("cor_method", "Correlation Method:",
                              choices = c("Pearson" = "pearson", 
                                          "Spearman" = "spearman", 
                                          "Kendall" = "kendall"),
                              selected = "pearson"),
                 
                 #display options for correlation matrix
                 checkboxInput("show_values", "Show Correlation Coefficients", value = TRUE),
                 sliderInput("cor_threshold", "Correlation Threshold:", min = 0, max = 1, value = 0, step = 0.1),
                 
                 #color scheme selection
                 selectInput("color_scheme", "Color Scheme:",
                             choices = c("Blue-Red" = "RdBu", 
                                         "Greens" = "Greens", 
                                         "Blues" = "Blues"),
                             selected = "RdBu")
               ),
               mainPanel(
                 div(class = "plot-container",
                     plotlyOutput("corMatrixPlot", height = "100%")
                 ),
                 tags$div(
                   tags$h3("Correlation Matrix Analysis"),
                   tags$p("WRITE REPORT  IN HERE")
                 )
               )
             )),
    
      tabPanel("Time Series",
           sidebarLayout(
             sidebarPanel(
               h4("Time Series"),
               
               #statistic selection
               selectInput("ts_statistic", "Select Statistic:", 
                           choices = unique(temp$statistic), selected = "Average"),
               
               #year selection
               selectInput("ts_year_type", "Select Year(s):",
                           choices = c("Individual Years", "Year Range"),
                           selected = "Year Range"),
               
               uiOutput("ts_individual_year_ui"),
               
               uiOutput("ts_year_range_ui"),
               
               pickerInput("ts_site", "Select Site:", choices = unique(temp$site),
                           selected = c("Whangārei (Northland)", "Auckland (Auckland)",
                                        "Wellington (Wellington)", "Blenheim (Marlborough)",
                                        "Christchurch (Canterbury)", "Invercargill (Southland)"),
                           options = list(`actions-box` = TRUE), multiple = TRUE)
           ),
             mainPanel(
               div(class = "plot-container",
                   #plotlyOutput("timePlot", height = "100%"),
                   plotlyOutput("avgtimePlot", height = "100%")
               ),
               
             )
           )),
    )
)


server <- function(input, output, session) {
  
  #reactive values to keep track of number of sites to compare
  rv <- reactiveValues(num_sites = 1) #default to 1 site
  
  observeEvent(input$add_site, { #add an additional site to compare when the "+" button is pressed
    if (rv$num_sites < length(unique(temp$site))) {
      rv$num_sites <- rv$num_sites + 1
    }
  })
  
  #preserve selected sites when adding a new site, so that the selections don't reset when you press "+"
  observe({
    for (i in seq_len(rv$num_sites)) {
      if (!is.null(input[[paste0("site", i)]])) {
        updateSelectInput(session, paste0("site", i), selected = input[[paste0("site", i)]])
      }
    }
  })
  
  output$comparison_sites_ui <- renderUI({
    if (input$comparison_type == "compare") {
      tagList(
        lapply(1:rv$num_sites, function(i) {
          selectInput(paste0("site", i), paste0("Select Site ", i), choices = unique(temp$site))
        })
      )
    }
  })
  
  output$add_site_ui <- renderUI({
    if (input$comparison_type == "compare") {
      if (rv$num_sites < length(unique(temp$site))) {
        actionButton("add_site", "+")  #show "+" button only if "Compare Sites" is selected
      }
    }
  })
  
  #show or hide UI elements based on year selection type
  output$individual_year_ui <- renderUI({
    if (input$year_type == "Individual Years") {
      selectInput("year", "Select Year(s):", choices = unique(temp$year), multiple = TRUE)
    } else {
      NULL
    }
  })
  
  output$year_range_ui <- renderUI({
    if (input$year_type == "Year Range") {
      sliderInput("year_range", "Select Year Range:", min = min(temp$year), max = max(temp$year),
                  value = c(min(temp$year), max(temp$year)), step = 1)
    } else {
      NULL
    }
  })
  
  output$box_individual_year_ui <- renderUI({
    if (input$box_year_type == "Individual Years") {
      selectInput("box_year", "Select Year(s):", choices = unique(temp$year), multiple = TRUE)
    } else {
      NULL
    }
  })
  
  output$box_year_range_ui <- renderUI({
    if (input$box_year_type == "Year Range") {
      sliderInput("box_year_range", "Select Year Range:", min = min(temp$year), max = max(temp$year),
                  value = c(min(temp$year), max(temp$year)), step = 1)
    } else {
      NULL
    }
  })
  
  output$cor_individual_year_ui <- renderUI({
    if (input$cor_year_type == "Individual Years") {
      selectInput("cor_year", "Select Year(s):", choices = unique(temp$year), multiple = TRUE)
    } else {
      NULL
    }
  })
  
  output$cor_year_range_ui <- renderUI({
    if (input$cor_year_type == "Year Range") {
      sliderInput("cor_year_range", "Select Year Range:", min = min(temp$year), max = max(temp$year),
                  value = c(min(temp$year), max(temp$year)), step = 1)
    } else {
      NULL
    }
  })

  
  output$ts_year_range_ui <- renderUI({
    if (input$ts_year_type == "Year Range") {
      sliderInput("ts_year_range", "Select Year Range:", sep="", min = 1966, max = max(temp$year),
                  value = c(2002, max(temp$year)), step = 1)
    } else {
      NULL
    }
  })
  
  output$ts_individual_year_ui <- renderUI({
    if (input$ts_year_type == "Individual Years") {
      selectInput("ts_year", "Select Year(s):", choices = unique(temp$year), multiple = TRUE)
    } else {
      NULL
    }
  })
  
  #filter data based on the selected year and season
  filtered_data <- reactive({
    data <- temp %>% filter(statistic == input$statistic)
    
    if (input$year_type == "Individual Years") {
      data <- data %>% filter(year %in% input$year)
    } else if (input$year_type == "Year Range") {
      data <- data %>% filter(year >= input$year_range[1] & year <= input$year_range[2])
    }
    
    if (input$season != "All") {
      data <- data %>% filter(season == input$season)
    }
    
    data
  })
  
  #filter data based on the selected stat, site, and year
  ts_data <- reactive({
    
    data <- temp %>% 
      filter(statistic == input$ts_statistic & site %in% input$ts_site) %>% 
      as_tsibble(key = site, index=date)
    
    
    
    if (input$ts_year_type == "Individual Years") {
      data <- data %>% filter(year %in% input$ts_year)
    } else if (input$ts_year_type == "Year Range") {
      data <- data %>% filter(year >= input$ts_year_range[1] & year <= input$ts_year_range[2])
    }
    
    
    data
  })
  
  output$distPlot <- renderPlotly({
    data <- filtered_data()
    
    title_text <- paste(input$plot_type, "for", input$site, "-", input$statistic, "-",
                        if(input$year_type == "Individual Years") {
                          paste("Year:", paste(input$year, collapse = ", "))
                        } else {
                          paste("Year Range:", paste(input$year_range[1], "-", input$year_range[2]))
                        },
                        "- Season:", input$season)
    
    p <- ggplot(data, aes(x = temperature)) + 
      theme_minimal()
    
    if (input$plot_type == "histogram") {
      p <- p + geom_histogram(binwidth = input$binwidth, fill = "blue", alpha = 0.7)
      
      if (input$overlay) {
        p <- p + geom_density(aes(y = ..count..), color = "red", fill = NA, size = 1)
      }
    } else if (input$plot_type == "density") {
      p <- p + geom_density(fill = "blue", alpha = 0.5)
    }
    
    if (input$site == "All Sites") {
      p <- p + facet_wrap(~site, scales = "free")
    }
    
    p <- p + ggtitle(title_text)
    
    ggplotly(p)
  })
  
  output$boxPlot <- renderPlotly({
    #filter data based on selected statistic, year, and season
    data <- temp %>% filter(statistic == input$box_statistic)
    
    if (input$box_year_type == "Individual Years") {
      data <- data %>% filter(year %in% input$box_year)
    } else if (input$box_year_type == "Year Range") {
      data <- data %>% filter(year >= input$box_year_range[1] & year <= input$box_year_range[2])
    }
    
    if (input$box_season != "All") {
      data <- data %>% filter(season == input$box_season)
    }
    
    if (input$comparison_type == "all") {
      title_text <- paste("Boxplot for All Sites -", input$box_statistic, "-",
                          if(input$box_year_type == "Individual Years") {
                            paste("Year:", paste(input$box_year, collapse = ", "))
                          } else {
                            paste("Year Range:", paste(input$box_year_range[1], "-", input$box_year_range[2]))
                          },
                          "- Season:", input$box_season)
    } else if (input$comparison_type == "compare") {
      selected_sites <- sapply(seq_len(rv$num_sites), function(i) input[[paste0("site", i)]])
      data <- data %>% filter(site %in% selected_sites)
      title_text <- paste("Boxplot Comparing Sites:", paste(selected_sites, collapse = ", "),
                          "- Statistic:", input$box_statistic, "-",
                          if(input$box_year_type == "Individual Years") {
                            paste("Year:", paste(input$box_year, collapse = ", "))
                          } else {
                            paste("Year Range:", paste(input$box_year_range[1], "-", input$box_year_range[2]))
                          },
                          "- Season:", input$box_season)
    }
    
    p <- ggplot(data, aes(x = factor(site), y = temperature)) +
      geom_boxplot() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8)) +  #rotate labels and reduce size
      labs(x = "Site")  #correct the x-axis label so it isn't "factor(site)"
    
    p <- p + ggtitle(title_text)
    
    ggplotly(p)
  })
  
  output$corMatrixPlot <- renderPlotly({
    #filter data to select the appropriate "statistic", year(s), and season across all sites
    data <- temp %>% filter(statistic == input$cor_statistic)
    
    if (input$cor_year_type == "Individual Years") {
      data <- data %>% filter(year %in% input$cor_year)
    } else if (input$cor_year_type == "Year Range") {
      data <- data %>% filter(year >= input$cor_year_range[1] & year <= input$cor_year_range[2])
    }
    
    if (input$cor_season != "All") {
      data <- data %>% filter(season == input$cor_season)
    }
    
    #pivot data to wider format, with sites as columns
    wide_data <- data %>%
      select(date, site, temperature) %>%
      tidyr::pivot_wider(names_from = site, values_from = temperature) %>%
      select(-date)
    
    #ensure all columns used for correlation are numeric
    wide_data <- wide_data %>% mutate(across(everything(), as.numeric))
    
    #calculate correlation matrix
    cor_matrix <- cor(wide_data, use = "complete.obs", method = input$cor_method)
    
    #apply correlation threshold
    cor_matrix[abs(cor_matrix) < input$cor_threshold] <- NA  #setting below-threshold correlations to NA
    
    #convert correlation matrix to long format for ggplot
    cor_data <- as.data.frame(as.table(cor_matrix))
    
    #ensure Var1 and Var2 are treated as factors
    cor_data$Var1 <- as.factor(cor_data$Var1)
    cor_data$Var2 <- as.factor(cor_data$Var2)
    
    #plot correlation matrix
    title_text <- paste("Correlation Matrix using", input$cor_method, "method",
                        "- Statistic:", input$cor_statistic, "-",
                        if(input$cor_year_type == "Individual Years") {
                          paste("Year:", paste(input$cor_year, collapse = ", "))
                        } else {
                          paste("Year Range:", paste(input$cor_year_range[1], "-", input$cor_year_range[2]))
                        }, "- Season:", input$cor_season)
    
    p <- ggplot(cor_data, aes(x = Var1, y = Var2, fill = Freq)) +
      geom_tile(color = "white", na.rm = TRUE) +
      scale_fill_gradientn(colors = RColorBrewer::brewer.pal(11, input$color_scheme), na.value = "grey90") +
      theme_minimal() +
      labs(x = "Site", y = "Site", fill = "Correlation",
           title = title_text) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    if (input$show_values) {
      p <- p + geom_text(aes(label = ifelse(is.na(Freq), "", round(Freq, 2))), size = 3)
    }
    
    ggplotly(p)
  })
  
  #output$timePlot <- renderPlotly({
   # data <- ts_data()
    
   # monthly_avg <- data %>%
   #   group_by(site, statistic, month_year) %>%
   #   summarise(avg_temp = mean(temperature, na.rm = TRUE)) %>%
   #   ungroup()
    
  #  p <- ggplot(monthly_avg, aes(x = factor(month_year, ordered=TRUE), y = avg_temp, group = site)) +
    #  geom_line(size=0.1) +
    #  labs(title = "Temperature Over Time (monthly averages)",
    #       x = "Date", y = "Temperature (\u00B0C)") +
    #  facet_wrap(~site, ncol=2) +
    #  stat_smooth(colour = "red", linewidth=0.5) + 
    #  theme_minimal()
    
    #ggplotly(p)
 # })
  
  output$avgtimePlot <- renderPlotly({
    data <- ts_data()
    data <- data %>%
      mutate(rolling_avg = rollmean(temperature, k=90, na.pad=TRUE))
    
    p <- ggplot(data, aes(x = date, y = rolling_avg, group = site)) +
      geom_line(size=0.1) +
      labs(title = "Temperature Over Time (90-day smoothing)",
           x = "Date", y = "Temperature (\u00B0C)") +
      facet_wrap(~site, ncol=2) +
      stat_smooth(colour = "red", linewidth=0.5) + 
      theme(plot.margin = unit(c(2,1,2,1), "cm"))
    
    ggplotly(p)
  })
  
}


shinyApp(ui = ui, server = server)
