package hxpy;

import cpp.Callable;

@:buildXml("<include name='${haxelib:hxpy}/hxpy/Build.xml' />")
@:include("Python.h")
@:keep
/**
 * Class that contains most of the variables and functions in hxpy!
 */
extern class Python
{
    /**
     * Python version as a whole
     */
    @:native('::String(PY_VERSION)')
	static var VERSION:String;

    /**
     * Major version number
     */
    @:native('::String(PY_MAJOR_VERSION)')
	static var VERSION_MAJOR:String;

    /**
     * Minor version number
     */
    @:native('::String(PY_MINOR_VERSION)')
	static var VERSION_MINOR:String;

    /**
     * Micro version number
     */
    @:native('::String(PY_MICRO_VERSION)')
	static var VERSION_MICRO:String;
    /**
     * Release level
     */
    @:native('::String(PY_RELEASE_LEVEL)')
	static var RELEASE_LEVEL:String;

    /**
     * Release serial number
     */ 
    @:native('::String(PY_RELEASE_SERIAL)')
	static var RELEASE_SERIAL:String;

    /**
     * Current Python state
     */
    static var STATE:Dynamic;

    /**
    *Function for tracing the Python copyright information.
    */
    @:native("Py_GetCopyright")
	public static function getCopyright():String;

    /**
    *Function for initializing the Python interpreter.
    */
    @:native("Py_Initialize")
	public static function initialize():Void;

    /**
    *Function for loading Python code from a string.
    @param pycode The actual Python code that is going to be run.
    */
    @:native("PyRun_SimpleString")
	public static function runSimpleString(pycode:String):Void;

	/**
     * Function for loading Python code from a file.
     * @param filetoParse The path of your Python script. (eg: script.py)
  */
	public static inline function runSimpleFile(filetoParse:String):Void {
      @:privateAccess
      PythonFile.runSimpleFile(filetoParse);
  	}
    
     /**
      * Calls a defined Python function without arguments from a script
      * @param funcName Function to call (eg: 'def foo(): print("Hi!")' -> Python.callFunction("foo"))
      */
     //@:native("PyObject_CallFunction")
     private static inline function callFunction(funcName:String):Void {
        @:privateAccess
        PythonHelper.callFunction(funcName);
     }
		
    /**
    *Function for closing a Python instance.
    */
    @:native("Py_Finalize")
	public static function finalize():Void;
    
}

@:cppFileCode('
#define PY_SSIZE_T_CLEAN
#ifdef _DEBUG
	#undef _DEBUG
	#include <Python.h>
	#define _DEBUG
#else
	#include <Python.h>
#endif
#include <string>
#include <iostream>
using std::string;
using namespace std;
')
@:keep
class PythonFile {
    /**
     * Function for loading Python code from a file.
     * @param filetoParse The path of your Python script. (eg: script.py)
     */
	private static function runSimpleFile(filetoParse:String) {
    	untyped __cpp__('
      		PyObject *obj = Py_BuildValue("s", filetoParse.c_str());
      		FILE* PScriptFile = _Py_fopen_obj(obj, "r+");
      		if(PScriptFile){
    			PyRun_SimpleFile(PScriptFile, filetoParse);
        		fclose(PScriptFile);
      		}
      		else{
        		std::cout << "File Not Found!";
    		} 
		');
	}
}

@:cppFileCode('
#include <Python.h>
#include <string>
#include <iostream>
#include <vector>
using std::string;
using std::vector;
using namespace std;
')
@:keep
class PythonHelper
{
    public static function callFunction(moduleName:String, funcName:String, ?parameters:Array<String>):Dynamic {
        var result:Dynamic = null;
        untyped __cpp__('
            PyObject *pName, *pModule, *pFunc, *pArgs, *pValue;
            vector<string> argsVec = {2};
            pModule = PyImport_ImportModule({0});
            if (!pModule) {
                PyErr_Print();
                std::cerr << "Failed to load module " << {0} << std::endl;
                return null;
            }

            pFunc = PyObject_GetAttrString(pModule, {1});
            if (!pFunc || !PyCallable_Check(pFunc)) {
                if (PyErr_Occurred())
                    PyErr_Print();
                std::cerr << "Cannot find or call function " << {1} << std::endl;
                Py_XDECREF(pFunc);
                Py_DECREF(pModule);
                return null;
            }

            pArgs = PyTuple_New(argsVec.size());
            for (size_t i = 0; i < argsVec.size(); ++i) {
                PyObject* pValue = PyUnicode_FromString(argsVec[i].c_str());
                if (!pValue) {
                    Py_DECREF(pArgs);
                    Py_DECREF(pModule);
                    PyErr_Print();
                    std::cerr << "Failed to convert argument" << std::endl;
                    return null;
                }
                PyTuple_SetItem(pArgs, i, pValue);
            }

            pValue = PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);

            if (pValue != NULL) {
                std::cout << "Function call successful." << std::endl;
                // Handle the result
                Py_DECREF(pValue);
            } else {
                PyErr_Print();
                std::cerr << "Call failed" << std::endl;
            }

            Py_XDECREF(pFunc);
            Py_DECREF(pModule);
        ', moduleName, funcName, parameters);
        return result;
    }
}
