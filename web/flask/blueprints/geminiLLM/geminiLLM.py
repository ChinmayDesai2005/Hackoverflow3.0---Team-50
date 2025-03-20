from flask import Blueprint, request
from blueprints.geminiLLM.helper import *
import shutil, os, base64

geminiLLM = Blueprint("geminiLLM", __name__)

PATH_FOR_IMAGES = "blueprints/geminiLLM/images/"

@geminiLLM.route("/")
def index():
    return "Summarize Endpoint!"

@geminiLLM.route('/', methods=['POST'])
def landing():
    imageList = os.listdir("blueprints/geminiLLM/images/")
    print(imageList)
    return "AapdaMitra Report Generation"

@geminiLLM.route('/generate-report', methods=['POST'])
def generateReport():
    if request.method == 'POST':
        # print(request.json)
        data = request.json
        print(f"New request received! {data}")
        # Initialize new Model
        model = DisasterAnalysis(data)
        
        # Get report generated
        report = model.generateReportFromData()
        # print(report)
        # os.remove('report.md')
        with open('report.md', "w") as f:
            f.write(report)

        # Get graph statements
        graphPhrases = model.generateGraphPhrases()
        # print(graphPhrases)

        # Clear Old Images

        shutil.rmtree(PATH_FOR_IMAGES)
        os.mkdir(PATH_FOR_IMAGES)

        # Generate graph code
        graphCode = model.generateGraphCodePython(graphPhrases, PATH_FOR_IMAGES) 

        # print(graphCode)
        # Execute graph code
        executeCodeFromArray(graphCode)

        # Generate response 
        response = {}

        imageList = os.listdir("blueprints/geminiLLM/images/")
        # print(imageList)
        response["graphs"] = []
        for image in imageList:
            with open(f"blueprints/geminiLLM/images/{image}", 'rb') as f:
                response["graphs"].append(json.dumps(base64.b64encode(f.read()).decode('utf-8')))

        # print(len(response['graphs']))
        # with open("report.md", 'a') as f:
        #     for graph in response["graphs"]:
                # f.write(f"\n![Report Graph](data:image/png;base64,{graph[1:-1]})")
        #         f.write(f"<img src=data:image/png;base64,{graph[1:-1]} width='250px' alt='Graph' />")

        with open("report.md", 'r') as f:
            response["report"] = f.read()
        

        # print(response)
        # Return response
        return response

    else:
        return "Hit this endpoint with a POST request"


@geminiLLM.route('/summarize-news', methods=['POST'])
def newsToSummary():
    try:
        # data = request.form.get('posts')
        data = request.json
        print(data)
        response = generateSummary(data['newsData']['results'])
        return {"summary": response}
    except Exception as e:
        print(e)
        return {"error": "something"}
    
@geminiLLM.route('/get-one-liner', methods=['POST'])
def getOneLiner():
    try:
        data = request.json
        response = generateOneLiner(data)
        return {'one-liner': response}
    
    except Exception as e:
        print(e)
        return {"error": "An error occurred!"}
    
@geminiLLM.route('/dailyreport', methods=['POST'])
def dailyReport():
    try:
        data = request.json

        # model = DisasterAnalysis(data)

        report = generateDailyReport(data)

        return {"daily-report": report}
    except Exception as e:
        print(f"Error in generating daily report: {e}")
        return {"error": "Failed to generate daily report."}, 500
    
@geminiLLM.route('/finalreport', methods=['POST'])
def RandomReport():
    try:
        data = request.json

        # model = DisasterAnalysis(data)

        report = generateRandomReport(data)

        return {"daily-report": report}
    except Exception as e:
        print(f"Error in generating daily report: {e}")
        return {"error": "Failed to generate daily report."}, 500