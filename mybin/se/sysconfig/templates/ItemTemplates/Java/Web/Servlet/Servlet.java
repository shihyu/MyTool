package $packagename$;

import java.io.*;
import java.text.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ extends HttpServlet {
    /**
     * Default constructor
     */
    public $safeitemname$() {
	// TODO: Add constructor code here
    }

    /**
     * Processes HTTP GET requests
     * 
     * @param request An HttpServletRequest object that contains the
     *                request the client has made of the servlet
     * @param response An HttpServletResponse object that contains
     *                 the response the servlet sends to the client
     * @throws IOException If an input or output error is detected
     *                     when the servlet handles the GET request
     * @throws ServletException If the request for the GET could not
     *                          be handled
     */
    public void doGet(HttpServletRequest request, HttpServletResponse response)
	throws IOException, ServletException
    {
	// generate the HTML response based on the request
	generateHtml(request, response);
    }

    /**
     * Processes HTTP POST requests
     * 
     * @param request An HttpServletRequest object that contains the
     *                request the client has made of the servlet
     * @param response An HttpServletResponse object that contains
     *                 the response the servlet sends to the client
     * @throws IOException If an input or output error is detected
     *                     when the servlet handles the POST request
     * @throws ServletException If the request for the POST could
     *                          not be handled
     */
    public void doPost(HttpServletRequest request, HttpServletResponse response)
	throws IOException, ServletException
    {
	// generate the HTML response based on the request
	generateHtml(request, response);
    }

    /**
     * Produces the HTML response given the HTTP request
     * 
     * @param request An HttpServletRequest object that contains the
     *                request the client has made of the servlet
     * @param response An HttpServletResponse object that contains
     *                 the response the servlet sends to the client
     * @throws IOException If an input or output error is detected
     *                     when the servlet handles the request
     * @throws ServletException If the request could not be handled
     */
    protected void generateHtml(HttpServletRequest request, HttpServletResponse response)
	throws IOException, ServletException
    {
	// set the response type
	response.setContentType("text/html");
	// get a reference to the response writer
	PrintWriter out = response.getWriter();
	out.println("<html>");
	// TODO: Add HTML generating code here
	out.println("</html>");
    }

}


