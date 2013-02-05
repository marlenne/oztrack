<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>
<c:set var="isoDateFormatPattern" value="yyyy-MM-dd"/>
<tags:page title="${project.title}: View Tracks" fluid="true">
    <jsp:attribute name="description">
        View and analyse animal tracking data in the ${project.title} project.
    </jsp:attribute>
    <jsp:attribute name="navExtra">
        <a id="projectMapOptionsBack" href="/projects/${project.id}"><span class="icon-chevron-left icon-white"></span> Back to project</a>
    </jsp:attribute>
    <jsp:attribute name="head">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/optimised/openlayers.css" type="text/css">
        <style type="text/css">
            #main {
                padding-bottom: 0;
            }
            #mapToolForm {
                padding-left:0px;
                padding-top:0px;
            }
            #animalsFilter {
                height: 90px;
                border: 1px solid #ccc;
                overflow-y: scroll;
            }
            .animalsFilterCheckbox {
                float: left;
                width: 15px;
                margin: 0;
                padding: 0;
            }
            .animalsFilterCheckbox input[type="checkbox"] {
                margin: 0 0 2px 0;
            }
            .animalsFilterSmallSquare {
                float: left;
                width: 12px;
                height: 12px;
                margin: 2px 5px;
                padding: 0;
            }
            .animalsFilterLabel {
                margin-left: 40px;
                padding: 0;
            }
            .animalCheckbox {
                float: left;
                width: 15px;
                margin: 5px 0;
            }
            .smallSquare {
                display: block;
                height: 14px;
                width: 14px;
                float: left;
                margin: 5px;
            }
            .animalHeader {
                padding: 0;
                height: 24px;
                line-height: 24px;
                margin-bottom: 0.5em;
            }
            .animalLabel {
                font-weight: bold;
                margin-left: 40px;
                margin-right: 65px;
                white-space: nowrap;
                overflow: hidden;
            }
            a.animalInfoToggle {
                text-decoration: none;
            }
            .animalInfo {
                margin-left: 8px;
                margin-right: 8px;
                margin-top: 0;
                margin-bottom: 0;
            }
            .animalInfo table {
                margin-top: 5px;
            }
            .layerInfo {
                margin: 0 0 0.5em 0;
                padding: 5px;
            }
            .layerInfoTitle {
                padding: 2px;
                border-bottom: 1px solid #ccc;
                background-color: #D8E0A8;
            }
            .layerInfoLabel {
                width: 7em;
            }
            a.layer-delete {
                float: right;
                margin-right: 3px;
                font-size: 11px;
                color: #666;
            }
            .paramTable {
                margin: 6px 0;
                width: 100%;
                background-color: #DBDBD0;
                border: 3px solid #DBDBD0;
            }
            .paramTable td {
                padding: 2px;
            }
            #savedAnalysesList .analysis-header {
                padding: 2px 4px;
                border-bottom: 1px solid #ccc;
                background-color: #D8E0A8;
            }
            #savedAnalysesList .analysis-header a {
                color: #444;
                font-weight: normal;
                text-decoration: none;
            }
            .analysis-header-timestamp {
                float: right;
                font-size: 11px;
                color: #666;
            }
            #savedAnalysesList .analysis-content {
                margin: 0 0 9px 0;
            }
            #previousAnalysesList .analysis-content {
                margin: 6px 0 9px 0;
                background-color: #DBDBD0;
                border: 1px solid transparent;
            }
            #previousAnalysesList .analysis-content-description {
                padding-top: 3px;
                padding-bottom: 3px;
                border-bottom: 1px solid #CCC;
            }
            .analysis-content-description {
                margin: 6px;
            }
            .analysis-content-description .analysis-content-description-text,
            .analysis-content-description .editable-container {
                font-style: italic;
            }
            .analysis-content-description .editable-empty {
                color: #666;
            }
            .analysis-content-params {
                margin: 6px;
            }
            #previousAnalysesList .analysis-content-actions {
                padding-top: 3px;
                padding-bottom: 3px;
                border-top: 1px solid #CCC;
            }
        </style>
    </jsp:attribute>
    <jsp:attribute name="tail">
        <script src="${pageContext.request.scheme}://maps.google.com/maps/api/js?v=3.9&sensor=false"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/optimised/openlayers.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/project-analysis.js"></script>
        <script type="text/javascript">
            function showParamTable(queryType) {
                $('.paramTable').hide();
                $('#paramTable-' + queryType).fadeIn('slow');
            }
            $(document).ready(function() {
                $('#navTrack').addClass('active');
                $('#projectMenuAnalysis').addClass('active');
                $("#projectMapOptionsTabs").tabs();
                $('#fromDateVisible').datepicker({
                    altField: "#fromDate",
                    minDate: new Date(${projectDetectionDateRange.minimum.time}),
                    maxDate: new Date(${projectDetectionDateRange.maximum.time}),
                    defaultDate: new Date(${projectDetectionDateRange.minimum.time})
                });
                $('#toDateVisible').datepicker({
                    altField: "#toDate",
                    minDate: new Date(${projectDetectionDateRange.minimum.time}),
                    maxDate: new Date(${projectDetectionDateRange.maximum.time}),
                    defaultDate: new Date(${projectDetectionDateRange.maximum.time})
                });
                <c:forEach items="${projectAnimalsList}" var="animal" varStatus="animalStatus">
                $('input[id=select-animal-${animal.id}]').change(function() {
                    analysisMap.toggleAllAnimalFeatures("${animal.id}", this.checked);
                    $('#selectAnimalConfirmationBox').show();
                    repositionSelectAnimalConfirmationBox();
                });
                </c:forEach>
                $('#selectAnimalConfirmationLink').click(function(e) {
                    analysisMap.toggleAllAnimalFeaturesCommit();
                    $('#selectAnimalConfirmationBox').fadeOut();
                });

                $('#select-animal-all').prop('checked', $('.select-animal:not(:checked)').length == 0);
                $('.select-animal').change(function (e) {
                    $('#select-animal-all').prop('checked', $('.select-animal:not(:checked)').length == 0);
                });
                $('#select-animal-all').change(function (e) {
                    $('.select-animal').prop('checked', $(this).prop('checked')).trigger('change');
                });

                $('#filter-animal-all').prop('checked', $('.filter-animal:not(:checked)').length == 0);
                $('.filter-animal').change(function (e) {
                    $('#filter-animal-all').prop('checked', $('.filter-animal:not(:checked)').length == 0);
                });
                $('#filter-animal-all').change(function (e) {
                    $('.filter-animal').prop('checked', $(this).prop('checked'));
                });

                $('#queryTypeSelect-MCP').trigger('click');

                var projectBounds = new OpenLayers.Bounds(
                    ${projectBoundingBox.envelopeInternal.minX}, ${projectBoundingBox.envelopeInternal.minY},
                    ${projectBoundingBox.envelopeInternal.maxX}, ${projectBoundingBox.envelopeInternal.maxY}
                );
                analysisMap = null;
                onResize();
                analysisMap = createAnalysisMap('projectMap', {
                    projectId: <c:out value="${project.id}"/>,
                    animalIds: [
                        <c:forEach items="${projectAnimalsList}" var="animal" varStatus="animalStatus">
                        ${animal.id}<c:if test="${!animalStatus.last}">,
                        </c:if>
                        </c:forEach>
                    ],
                    projectBounds: projectBounds,
                    animalBounds: {
                        <c:forEach items="${animalBoundingBoxes}" var="animalBoundingBoxEntry" varStatus="animalBoundingBoxEntryStatus">
                        ${animalBoundingBoxEntry.key}: new OpenLayers.Bounds(
                            ${animalBoundingBoxEntry.value.envelopeInternal.minX}, ${animalBoundingBoxEntry.value.envelopeInternal.minY},
                            ${animalBoundingBoxEntry.value.envelopeInternal.maxX}, ${animalBoundingBoxEntry.value.envelopeInternal.maxY}
                        )<c:if test="${!animalBoundingBoxEntryStatus.last}">,
                        </c:if>
                        </c:forEach>
                    },
                    animalColours: {
                        <c:forEach items="${projectAnimalsList}" var="animal" varStatus="animalStatus">
                        ${animal.id}: '${animal.colour}'<c:if test="${!animalStatus.last}">,
                        </c:if>
                        </c:forEach>
                    },
                    minDate: new Date(${projectDetectionDateRange.minimum.time}),
                    maxDate: new Date(${projectDetectionDateRange.maximum.time}),
                    onAnalysisCreate: function(layerName, analysisUrl) {
                        addAnalysis(layerName, analysisUrl, new Date(), false);
                    },
                    onAnalysisError: function(message) {
                        $('#projectMapSubmit').prop('disabled', false);
                        $('#projectMapCancel').fadeOut();
                        jQuery('#errorDialog')
                            .text(message)
                            .dialog({
                                title: 'Error',
                                modal: true,
                                resizable: false,
                                buttons: {
                                    'Close': function() {
                                        $(this).dialog('close');
                                    }
                                }
                            });
                    },
                    onAnalysisSuccess: function() {
                        $('#projectMapSubmit').prop('disabled', false);
                        $('#projectMapCancel').fadeOut();
                        $('a[href="#animalPanel"]').trigger('click');
                    }
                });
                <c:forEach items="${savedAnalyses}" var="analysis">
                addAnalysis(
                    '${analysis.analysisType.displayName}',
                    '${pageContext.request.contextPath}/projects/${analysis.project.id}/analyses/${analysis.id}',
                    new Date(${analysis.createDate.time}),
                    true
                );
                </c:forEach>
                <c:forEach items="${previousAnalyses}" var="analysis">
                addAnalysis(
                    '${analysis.analysisType.displayName}',
                    '${pageContext.request.contextPath}/projects/${analysis.project.id}/analyses/${analysis.id}',
                    new Date(${analysis.createDate.time}),
                    false
                );
                </c:forEach>
                $(window).resize(onResize);
                $(window).resize(repositionSelectAnimalConfirmationBox);
                $('#animalPanel').scroll(repositionSelectAnimalConfirmationBox);
                repositionSelectAnimalConfirmationBox();
            });
            function addAnalysis(layerName, analysisUrl, analysisCreateDate, saved) {
                var analysisContainer = $('<li class="analysis">');
                var analysisHeader = $('<div class="analysis-header">');
                if (!saved) {
                    var analysisTimestamp = $('<span class="analysis-header-timestamp">')
                        .text(moment(analysisCreateDate).format('YYYY-MM-DD HH:mm'));
                    analysisHeader.append(analysisTimestamp);
                }
                var analysisLink = $('<a>')
                    .attr('href', 'javascript:void(0);')
                    .text(layerName)
                    .click(function(e) {
                        var parent = $(this).closest('.analysis');
                        var content = parent.find('.analysis-content');
                        if (content.length != 0) {
                            content.slideToggle();
                        }
                        else {
                            parent.append(getAnalysisContent(analysisUrl, layerName, analysisCreateDate, saved));
                        }
                    });
                analysisHeader.append(analysisLink);
                analysisContainer.append(analysisHeader);
                if (saved) {
                    analysisContainer.append(getAnalysisContent(analysisUrl, layerName, analysisCreateDate, saved));
                    $('#savedAnalysesTitle').fadeIn();
                    $('#savedAnalysesList').fadeIn().prepend(analysisContainer);
                }
                else {
                    $('#previousAnalysesTitle').fadeIn();
                    $('#previousAnalysesList').fadeIn().prepend(analysisContainer);
                }
            }
            function getAnalysisContent(analysisUrl, layerName, analysisCreateDate, saved) {
                var div = $('<div class="analysis-content">').hide();
                $.ajax({
                    url: analysisUrl,
                    type: 'GET',
                    error: function(xhr, textStatus, errorThrown) {
                    },
                    complete: function (xhr, textStatus) {
                        if (textStatus == 'success') {
                            var analysis = $.parseJSON(xhr.responseText);
                            if (saved) {
                                var descriptionDiv = $('<div class="analysis-content-description">');
                                <sec:authorize access="hasPermission(#project, 'write')">
                                var editLink = $('<a style="float: right; padding: 0 6px;">')
                                    .attr('href', 'javascript:void(0);')
                                    .append($('<img src="${pageContext.request.contextPath}/img/page_white_edit.png" />'))
                                    .click(function(e) {
                                        e.stopPropagation();
                                        $(this).closest('.analysis-content').find('.analysis-content-description .analysis-content-description-text').editable('toggle');
                                    });
                                descriptionDiv.append(editLink);
                                </sec:authorize>
                                descriptionDiv.append($('<div class="analysis-content-description-text">')
                                    .text(analysis.description || '')
                                    <sec:authorize access="hasPermission(#project, 'write')">
                                    .editable({
                                        type: 'textarea',
                                        toggle: 'manual',
                                        emptytext: 'No description entered.',
                                        url: function(params) {
                                            jQuery.ajax({
                                                url: analysisUrl + '/description',
                                                type: 'PUT',
                                                contentType: "text/plain",
                                                data: params.value,
                                                success: function() {
                                                },
                                                error: function() {
                                                    alert('Could not save description.');
                                                }
                                            });
                                        }
                                    })
                                    </sec:authorize>
                                );
                                div.append(descriptionDiv);
                            }

                            var paramsTable = $('<table class="analysis-content-params">');
                            if (analysis.params.fromDate) {
                                paramsTable.append(
                                    '<tr>' +
                                    '<td class="layerInfoLabel">Date From:</td>' +
                                    '<td>' + analysis.params.fromDate + '</td>' +
                                    '</tr>'
                                );
                            }
                            if (analysis.params.toDate) {
                                paramsTable.append(
                                    '<tr>' +
                                    '<td class="layerInfoLabel">Date To:</td>' +
                                    '<td>' + analysis.params.toDate + '</td>' +
                                    '</tr>'
                                );
                            }
                            paramsTable.append(
                                '<tr>' +
                                '<td class="layerInfoLabel">Animals: </td>' +
                                '<td>' + analysis.params.animalNames.join(', ') + '</td>' +
                                '</tr>'
                            );
                            <c:forEach items="${analysisTypeList}" var="analysisType">
                            if (analysis.params.queryType == '${analysisType}') {
                                <c:forEach items="${analysisType.parameterTypes}" var="parameterType">
                                if (analysis.params.${parameterType.identifier}) {
                                    paramsTable.append(
                                        '<tr>' +
                                        '<td class="layerInfoLabel">${parameterType.displayName}: </td>' +
                                        '<td>' + analysis.params.${parameterType.identifier} + ' ${parameterType.units}</td>' +
                                        '</tr>'
                                    );
                                }
                                </c:forEach>
                            }
                            </c:forEach>
                            div.append(paramsTable);

                            var actionsList = $('<ul class="analysis-content-actions icons">');
                            actionsList.append($('<li>')
                                .addClass('add-layer')
                                .append(
                                    $('<a>')
                                        .attr('href', 'javascript:void(0);')
                                        .text('Add anlaysis to map')
                                        .click(function(e) {
                                            analysisMap.addAnalysisLayer(analysisUrl, layerName);
                                        })
                                )
                            );
                            <sec:authorize access="hasPermission(#project, 'write')">
                            actionsList.append($('<li>')
                                .addClass(saved ? 'delete' : 'create')
                                .append(
                                    $('<a>')
                                        .attr('href', 'javascript:void(0);')
                                        .text(saved ? 'Remove analysis' : 'Save analysis')
                                        .click(function(e) {
                                            jQuery.ajax({
                                                url: analysisUrl + '/saved',
                                                type: 'PUT',
                                                contentType: "application/json",
                                                data: (saved ? 'false' : 'true'),
                                                success: function() {
                                                    addAnalysis(layerName, analysisUrl, analysisCreateDate, !saved);
                                                    var li = $(e.target).closest('li.analysis');
                                                    if (li.siblings().length == 0) {
                                                        li.parent().prev().andSelf().fadeOut();
                                                    }
                                                    li.remove();
                                                },
                                                error: function() {
                                                    alert('Could not save analysis.');
                                                }
                                            });
                                        })
                                )
                            );
                            </sec:authorize>
                            div.append(actionsList);

                            div.slideDown();
                        }
                    }
                });
                return div;
            }
            function onResize() {
                var mainHeight = $(window).height() - $('#header').outerHeight();
                $('#projectMapOptions').height(mainHeight);
                var panelPadding =
                    parseInt($('#projectMapOptions .ui-tabs-panel').css('padding-top')) +
                    parseInt($('#projectMapOptions .ui-tabs-panel').css('padding-bottom'));
                $('#projectMapOptions .ui-tabs-panel').height(
                    $('#projectMapOptions').innerHeight() -
                    $('#projectMapOptions .ui-tabs-nav').outerHeight() -
                    panelPadding
                );
                $('#projectMap').height(mainHeight);
                if (analysisMap) {
                    analysisMap.updateSize();
                }
            }
            function repositionSelectAnimalConfirmationBox() {
                $('#selectAnimalConfirmationBox').position({
                    my: 'center bottom',
                    at: 'center bottom',
                    of: '#animalPanel'
                });
            }
        </script>
    </jsp:attribute>
    <jsp:body>
        <div id="mapTool" class="mapTool">

        <div id="projectMapOptions">
        <div id="projectMapOptionsInner">
        <div id="projectMapOptionsTabs">
            <ul>
                <li><a href="#animalPanel">Results</a></li>
                <li><a href="#homeRangeCalculatorPanel">Analysis</a></li>
                <li><a href="#previousAnalysesPanel">History</a></li>
            </ul>
            <div id="animalPanel">
                <div class="animalHeader" style="margin-bottom: 10px; border-bottom: 1px solid #ccc;">
                <div class="animalCheckbox">
                    <input
                        id="select-animal-all"
                        type="checkbox"
                        style="float: left; margin: 0;" />
                </div>
                <div class="smallSquare" style="background-color: transparent;"></div>
                <div>Select all</div>
                </div>

                <c:forEach items="${projectAnimalsList}" var="animal" varStatus="animalStatus">
                    <c:set var="showAnimalInfo" value="${animalStatus.index == 0}"/>
                    <div class="animalHeader">
                        <div class="btn-group" style="float: right;">
                            <button
                                id="buttonShowHide${animal.id}"
                                class="btn btn-mini"
                                onclick="var infoElem = $(this).parent().parent().next(); $(this).text(infoElem.is(':visible') ? 'Expand' : 'Shrink'); infoElem.slideToggle();">
                                ${showAnimalInfo ? 'Shrink' : 'Expand'}
                            </button>
                            <button class="btn btn-mini dropdown-toggle" data-toggle="dropdown">
                                <span class="caret"></span>
                            </button>
                            <ul class="dropdown-menu pull-right">
                                <li><a href="javascript:void(0);" onclick="analysisMap.zoomToAnimal(${animal.id});">Zoom to animal</a></li>
                                <li><a href="${pageContext.request.contextPath}/exportKML?projectId=${project.id}&animalId=${animal.id}">Export as KML</a></li>
                            </ul>
                        </div>

                        <div class="animalCheckbox">
                            <input id="select-animal-${animal.id}" class="select-animal" style="float: left; margin: 0;" type="checkbox" name="animalCheckbox" value="${animal.id}" checked="checked">
                        </div>

                        <div class="smallSquare" style="background-color: ${animal.colour};"></div>

                        <div class="animalLabel">
                            <a class="animalInfoToggle" href="javascript:void(0);" onclick="$('#buttonShowHide${animal.id}').click();">${animal.animalName}</a>
                        </div>
                    </div>
                    <div id="animalInfo-${animal.id}" class="animalInfo" style="display: ${showAnimalInfo ? 'block' : 'none'};">
                    </div>
                </c:forEach>
                
                <div id="selectAnimalConfirmationBox" style="display: none; position: absolute; background-color: #263F00; color: white; opacity: 0.80; padding: 10px; border-radius: 6px 6px 0 0;">
                    <a id="selectAnimalConfirmationLink" href="javascript:void(0);" style="color: white; font-weight: bold;">Click to finish selecting animals</a>
                </div>
            </div>

            <div id="homeRangeCalculatorPanel">

                <form id="mapToolForm" class="form-vertical" method="POST" onsubmit="return false;">
                    <input id="projectId" type="hidden" value="${project.id}"/>
                    <fieldset>
                    <div class="control-group" style="margin-bottom: 9px;">
                        <div style="margin-bottom: 9px; font-weight: bold;">
                            <span>Date Range</span>
                            <div class="help-popover" title="Date Range">
                                Choose a date range from within your data file for analysis.
                                If left blank, all data for the selected animals will be included in the analysis.
                            </div>
                        </div>
                        <div class="controls">
                            <input id="fromDate" type="hidden"/>
                            <input id="toDate" type="hidden"/>
                            <input id="fromDateVisible" type="text" class="datepicker" placeholder="From" style="margin-bottom: 3px; width: 80px;"/> -
                            <input id="toDateVisible" type="text" class="datepicker" placeholder="To" style="margin-bottom: 3px; width: 80px;"/>
                        </div>
                    </div>
                    <div class="control-group" style="margin-bottom: 9px;">
                        <div style="margin-bottom: 9px; font-weight: bold;">
                            <span>Animals</span>
                            <div class="help-popover" title="Animals">
                                Choose one or more animals for analysis and visualisation.
                                OzTrack can generate layers for multiple animals at a time; however, the processing time is
                                positively related to the number of animals and location fixes included in the analysis.
                            </div>
                        </div>
                        <div id="animalsFilter" class="controls">
                            <div style="background-color: #d8e0a8;">
                            <div class="animalsFilterCheckbox">
                                <input
                                    id="filter-animal-all"
                                    type="checkbox"
                                    style="width: 15px;" />
                            </div>
                            <div class="animalsFilterSmallSquare" style="background-color: transparent;"></div>
                            <div class="animalsFilterLabel">Select all</div>
                            </div>
                            <div style="clear: both;"></div>
                            <c:forEach items="${projectAnimalsList}" var="animal" varStatus="animalStatus">
                            <div class="animalsFilterCheckbox">
                                <input
                                    id="filter-animal-${animal.id}"
                                    class="filter-animal"
                                    name="animal"
                                    type="checkbox"
                                    value="${animal.id}"
                                    style="width: 15px;"
                                    <c:if test="${animalStatus.first}">checked="checked"</c:if> />
                            </div>
                            <div class="animalsFilterSmallSquare" style="background-color: ${animal.colour};"></div>
                            <div class="animalsFilterLabel">${animal.animalName}</div>
                            <div style="clear: both;"></div>
                            </c:forEach>
                        </div>
                    </div>
                    <div class="control-group" style="margin-bottom: 9px;">
                        <div style="margin-bottom: 9px; font-weight: bold;">Layer Type</div>
                        <div class="controls">
                            <table class="queryType" style="width: 100%;">
                                <c:forEach items="${mapLayerTypeList}" var="mapLayerType">
                                <tr>
                                    <td style="padding: 0 5px; vertical-align: top;">
                                        <input type="radio"
                                            name="queryTypeSelect"
                                            id="queryTypeSelect-${mapLayerType}"
                                            value="${mapLayerType}"
                                            onClick="showParamTable('${mapLayerType}')"
                                        />
                                    </td>
                                    <td id="${mapLayerType}">
                                        <label style="display: inline-block; margin: 2px 0 0 0;" for="queryTypeSelect-${mapLayerType}">${mapLayerType.displayName}</label>
                                        <c:if test="${not empty mapLayerType.explanation}">
                                        <div class="help-popover" title="${mapLayerType.displayName}">
                                            ${mapLayerType.explanation}
                                        </div>
                                        </c:if>
                                    </td>
                                </tr>
                                </c:forEach>
                                <c:forEach items="${analysisTypeList}" var="analysisType">
                                <tr>
                                    <td style="padding: 0 5px; vertical-align: top; width: 16px;">
                                        <input type="radio"
                                            name="queryTypeSelect"
                                            id="queryTypeSelect-${analysisType}"
                                            value="${analysisType}"
                                            onClick="showParamTable('${analysisType}')"
                                        />
                                    </td>
                                    <td id="${analysisType}">
                                        <label style="display: inline-block; margin: 2px 0 0 0;" for="queryTypeSelect-${analysisType}">${analysisType.displayName}</label>
                                        <c:if test="${not empty analysisType.explanation}">
                                        <div class="help-popover" title="${analysisType.displayName}">
                                            ${analysisType.explanation}
                                        </div>
                                        </c:if>
                                        <table id="paramTable-${analysisType}" class="paramTable" style="display: none;">
                                            <c:set var="foundAdvancedParameterType" value="false"/>
                                            <c:forEach items="${analysisType.parameterTypes}" var="parameterType">
                                            <c:if test="${!foundAdvancedParameterType and parameterType.advanced}">
                                            <c:set var="foundAdvancedParameterType" value="true"/>
                                            <tr>
                                                <td colspan="2">
                                                    <div style="margin-bottom: 3px;">
                                                        <a href="javascript:void(0);" onclick="$(this).closest('tr').nextAll().fadeToggle();">Advanced parameters</a>
                                                    </div>
                                                </td>
                                            </tr>
                                            </c:if>
                                            <tr <c:if test="${parameterType.advanced}">style="display: none;"</c:if>>
                                                <td style="white-space: nowrap; width: 10px;">${parameterType.displayName}</td>
                                                <td class="${(not empty parameterType.units) ? 'input-append' : ''}" style="margin: 0;">
                                                    <c:choose>
                                                    <c:when test="${parameterType.options != null}">
                                                    <select class="paramField-${analysisType}" style="width: 180px;" name="${parameterType.identifier}">
                                                    <c:forEach items="${parameterType.options}" var="option">
                                                    <option
                                                        value="${option.value}"
                                                        <c:if test="${parameterType.defaultValue == option.value}">selected="selected"</c:if>
                                                        >${option.title}</option>
                                                    </c:forEach>
                                                    </select>
                                                    </c:when>
                                                    <c:when test="${parameterType.dataType == 'boolean'}">
                                                    <input
                                                        class="paramField-${analysisType} checkbox"
                                                        name="${parameterType.identifier}"
                                                        type="checkbox"
                                                        <c:if test="${parameterType.defaultValue == 'true'}">checked="checked"</c:if>
                                                        value="true"
                                                        style="margin: 4px 1px;" />
                                                    </c:when>
                                                    <c:otherwise>
                                                    <input
                                                        class="paramField-${analysisType} input-mini"
                                                        name="${parameterType.identifier}"
                                                        type="text"
                                                        <c:if test="${not empty parameterType.defaultValue}">
                                                        value="${parameterType.defaultValue}"
                                                        </c:if>
                                                        style="margin-bottom: 3px; text-align: right;"/>
                                                    <c:if test="${not empty parameterType.units}">
                                                    <span class="add-on">${parameterType.units}</span>
                                                    </c:if>
                                                    </c:otherwise>
                                                    </c:choose>
                                                </td>
                                                <td style="width: 10px;">
                                                    <c:if test="${not empty parameterType.explanation}">
                                                    <div class="help-popover" title="${parameterType.displayName}">
                                                        ${parameterType.explanation}
                                                    </div>
                                                    </c:if>
                                                </td>
                                            </tr>
                                            </c:forEach>
                                        </table>
                                    </td>
                                </tr>
                                </c:forEach>
                            </table>
                        </div>
                    </div>
                    </fieldset>
                    <div style="margin-top: 18px;">
                        <input id="projectMapSubmit" class="btn btn-primary" type="button" value="Calculate"
                            onclick="$('#projectMapSubmit').prop('disabled', true); $('#projectMapCancel').fadeIn(); analysisMap.addProjectMapLayer();" />
                        <input id="projectMapCancel" class="btn" style="display: none;" type="button" value="Cancel"
                            onclick="analysisMap.deleteCurrentAnalysis(); $('#projectMapSubmit').prop('disabled', false); $('#projectMapCancel').fadeOut();" />
                    </div>
                </form>
            </div>

            <div id="previousAnalysesPanel">
                <div id="savedAnalysesTitle" style="display: none; margin-bottom: 9px; font-weight: bold;">Saved Analyses</div>
                <ul id="savedAnalysesList" class="unstyled" style="display: none;">
                </ul>
                <div id="previousAnalysesTitle" style="display: none; margin-bottom: 9px; font-weight: bold;">Previous Analyses</div>
                <ul id="previousAnalysesList" class="icons" style="display: none;">
                </ul>
            </div>
        </div>
        </div>
        </div>

        <div id="projectMap"></div>

        <div style="clear:both;"></div>

        </div>
        
        <div id="errorDialog"></div>
    </jsp:body>
</tags:page>