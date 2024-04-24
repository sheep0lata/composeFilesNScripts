from flask import *
import sys
app = Flask(__name__)
sys.path.append('/home/defaultname/webapps/swagify/htdocs')

@app.route('/')
def main(): 
    return render_template("index.html")


@app.errorhandler(404)
def custom404(e):
    return render_template("404.html"), 404

if __name__ == '__main__':
	app.run(host="0.0.0.0", port=80, debug=True)
