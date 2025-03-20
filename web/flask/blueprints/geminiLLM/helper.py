import google.generativeai as genai
import os
import json
import matplotlib
import matplotlib.pyplot as plt

os.environ["KMP_DUPLICATE_LIB_OK"]="TRUE"
matplotlib.use('agg')
genai.configure(api_key=os.environ['GEMINI_API_KEY'])
MODEL = genai.GenerativeModel('gemini-1.5-flash')

def load_data(pathToData):
    with open(pathToData, "r") as f:
        return json.loads(f.read())
    
def executeCodeFromArray(codeArray: list[str]):
    for graph in codeArray:
        graph = graph.splitlines()
        print(graph, sep="\n")
        for line in graph:
            try:
                print(line)
                eval(line)
            except Exception as e:
                print(line)
                print(e)
        plt.clf()
    
def imageToB64(image):
    pass

def generateSummary(data):
    for post in data:
        post['post_body_full'] = ""
    response = MODEL.generate_content(f'''The data given below is multiple news articles scraped from different sources related to disasters.
                                    Read the data and generate a brief summary aggregating the data from multiple posts into a singular quick read paragraph with color coding and markdown.
                                      Don't change the font only give colors and boldness in the markdown. Only keep a maximum of three colors.
                                      Return nothing if the input is an empty array. Try to extract information about specific details related to specific disasters. For example if the content is of cyclone
                                        then the summary should include the location, time, impact of the cyclone, speed of cyclone, landfall location, deaths, people affected, and various NDRF safe shelters which were
                                      created for the help of the people affected by the cyclone. Similarly for flood area affected, people affected, deaths, and various NDRF safe shelters which were created for the help of the people affected by the flood. and other such details.
                                      I want the summary to be extremely detailed and informative with at least 1-2 pages of relevant content in paragraph format. Use markdown color as green and red to show good and bad information respectively.
                                      In the start just give a basic smaller summary of the data in points format like No of total people died, No of people affected, No of safe shelters created, site of landfall or site/ground location of disaster etc. and then give a detailed summary of the data.
                                        The summary aims to summarize news articles for NDRF to get information from. {data}''')
    print(response.text)
    return response.text


def generateOneLiner(data):
    return (MODEL.generate_content(f'''Read the given data and generate a one liner summary of it.
                                    Make sure the summary is short (one-line).
                                    The summary must include the disaster type, location and time mentioned in the data. {data}''').text)
        
def generateDailyReport(data):
    return (MODEL.generate_content(f'''Create a detailed report about the data which is recieved from the one liner information and try to add details about deaths, people lost house, damged occured to the goverment property and all related information which can be usefull for the 
                                    showing of good report. Try to divide the report in 2 part the first part is the points wise statistics about the topic related to deduce. After the points give a detailed information about the topic and try to make it ectremely detailed with 
                                   information being accurate{data}''').text)

def generateRandomReport(data):
    return (MODEL.generate_content(f'''Create a detailed Report from the data which is shared by the system for the same. {data}''').text)
        

class DisasterAnalysis:
    def __init__(self, data):
        self.data = data

        
        self.chat = MODEL.start_chat()
        print("new object for gemini created")

    def generateReportFromData(self):
        return (self.chat.send_message(f'''The data provided below is a JSON data of various social media posts related to disasters or emergency events.
                                            Analyzing the data and present a short summary for each post in the context of disaster management.Also mention the authenticity of the post in the summary.
                                            The report should provide actionable insights in context to the data.
                                            Do not add any Limitations and Conclusion section. Only return the report.
                                            Do not give summary property by property. Only include information that would help mitigate the event.
                                            Add appropriate colors to Authenticity only in the markdown.
                                            {self.data}''').text)
    
    def generateGraphPhrases(self):
        return (self.chat.send_message(rf'''Generate four unique phrases from which graphs can be made that will help visualize the information from the data.
                                            For example, '90% of posts were from Twitter rest 10% were from News websites' or '75% of posts were authentic and 25% were fake'.
                                            Do not give graph statements but phrases for graphs.
                                            Do not give graph phrases where all the labels have the same value or there is only one label in the whole graph.
                                            Do not include any dates in the phrase.
                                            Give nothing but the graph phrases including the data needed to make those graphs.
                                            No formatting and new line for each statement.''').text)
    

    def generateGraphCodePython(self, graphPhrases, pathForSaving):
        graphCode = self.chat.send_message(f''' Below are statements to generate graphs from:
                                            {graphPhrases}
                                            Carefully ready each statement and choose which graph will best help represent that data (line, pie, chart, scatter, etc).
                                            Finally, generate a JSON array consisting of the lines of code to generate those graphs seperately using python and matplotlib that the eval function of python can directly run.
                                            Add a line for saving to '{pathForSaving}' the generated graph at the end instead of using .show().
                                            It is important that you do not declare any variables as they raise an error in eval(), directly use the corresponding data in the function parameters.
                                            No semicolons only newlines.
                                            Final output should only be a single json array and no stray text or explanations. No formatting.''').text
        
        print(graphCode)
        return json.loads(graphCode[8:len(graphCode) - 4])