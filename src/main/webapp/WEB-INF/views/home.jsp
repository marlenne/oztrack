<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>
<tags:page title="Home">
	<jsp:attribute name="head">
        <link rel="stylesheet" href="<c:url value="/js/openlayers/theme/default/style.css"/>" type="text/css">
        <link rel="stylesheet" href="<c:url value="/js/openlayers/theme/default/google.css"/>" type="text/css">
        <style type="text/css">
            #homeMap {
                margin: 20px 0 0 0;
                height: 500px;
                background-color:#e6e6c0;
                padding: 8px;
                -khtml-border-radius: 10px;
                -webkit-border-radius: 10px;
                -moz-border-radius: 10px;
                -ms-border-radius: 10px;
                -o-border-radius: 10px;
                border-radius: 10px;
            }
            .home-popup {
                margin-top: 0;
                padding: 0 10px;
                font-size: 11px;
            }
            .home-popup-attr-name {
                font-weight: bold;
                margin-bottom: 0.25em;
            }
            .home-popup-attr-value {
                margin-bottom: 0.75em;
            }
        </style>
        <script src="http://maps.google.com/maps/api/js?v=3.9&sensor=false"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/openlayers/OpenLayers.js"></script>
        <script type="text/javascript" src="<c:url value="/js/home.js"/>"></script>
        <script type="text/javascript">
            $(document).ready(function() {
                $('#navHome').addClass('active');
                map = createHomeMap('homeMap');
            });
        </script>
    </jsp:attribute>
	<jsp:body>
        <div id="welcome" class="fade in">
            <button class="close" data-dismiss="alert">×</button>
            ${text}
        </div>
        <div style="clear: both;"></div>
        <div id="homeMap"></div>
	</jsp:body>
</tags:page>
