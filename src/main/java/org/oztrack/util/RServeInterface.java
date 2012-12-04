package org.oztrack.util;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Locale;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.oztrack.data.model.Analysis;
import org.oztrack.data.model.AnalysisParameter;
import org.oztrack.data.model.PositionFix;
import org.oztrack.data.model.Project;
import org.oztrack.data.model.types.AnalysisParameterType;
import org.oztrack.data.model.types.AnalysisType;
import org.oztrack.error.RServeInterfaceException;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPDouble;
import org.rosuda.REngine.REXPInteger;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REXPNull;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.RList;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;

public class RServeInterface {
    protected final Log logger = LogFactory.getLog(getClass());

    private RConnection rConnection;
    private String rWorkingDir;

    public RServeInterface() {
    }

    public void createKml(Analysis analysis, List<PositionFix> positionFixList) throws RServeInterfaceException {
        startRConnection();
        Project project = analysis.getProject();

        String srs =
            StringUtils.isNotBlank(project.getSrsIdentifier())
            ? project.getSrsIdentifier().toLowerCase(Locale.ENGLISH)
            : "epsg:3577";
        createRPositionFixDataFrame(positionFixList, srs);

        switch (analysis.getAnalysisType()) {
            case MCP:
                writeMCPKmlFile(analysis, srs);
                break;
            case KUD:
                writeKernelUDKmlFile(analysis, srs);
                break;
            case AHULL:
                writeAlphahullKmlFile(analysis, srs);
                break;
            case HEATMAP_POINT:
                writePointHeatmapKmlFile(analysis, srs);
                break;
            case HEATMAP_LINE:
                writeLineHeatmapKmlFile(analysis, srs);
                break;
            default:
                throw new RServeInterfaceException("Unhandled AnalysisType: " + analysis.getAnalysisType());
        }

        rConnection.close();
    }

    private void startRConnection() throws RServeInterfaceException {
        if (StartRserve.checkLocalRserve()) {
            try {
                this.rConnection = new RConnection();
                this.rConnection.setSendBufferSize(10485760);
            }
            catch (RserveException e) {
                throw new RServeInterfaceException("Error starting Rserve.", e);
            }

            try {
                this.rWorkingDir = rConnection.eval("getwd()").asString() + File.separator;
            }
            catch (Exception e) {
                throw new RServeInterfaceException("Error getting Rserve working directory.", e);
            }
            String osname = System.getProperty("os.name");
            if (StringUtils.startsWith(osname, "Windows")) {
                this.rWorkingDir = this.rWorkingDir.replace("\\","/");
            }

            loadLibraries();
            loadScripts();
        }
        else {
            throw new RServeInterfaceException("Could not start Rserve.");
        }
    }

    private void loadLibraries() throws RServeInterfaceException {
        String[] libraries = new String[] {
            "adehabitatHR",
            "adehabitatMA",
            "shapefiles",
            "rgdal",
            "alphahull",
            "sp",
            "raster",
            "plyr",
            "spatstat",
            "maptools",
            "Grid2Polygons",
            "RColorBrewer",
            "googleVis",
            "spacetime",
            "plotKML"
        };
        for (String library : libraries) {
            try {
                this.rConnection.voidEval("library(" + library + ")");
            }
            catch (RserveException e) {
                throw new RServeInterfaceException("Error loading '" + library + "' library.", e);
            }
        }
    }

    private void loadScripts() throws RServeInterfaceException {
        String[] scriptFileNames = new String[] {
            "alphahull.r",
            "heatmap.r"
        };
        for (String scriptFileName : scriptFileNames) {
            String scriptString = null;
            try {
                scriptString = IOUtils.toString(getClass().getResourceAsStream("/r/" + scriptFileName), "UTF-8");
            }
            catch (IOException e) {
                throw new RServeInterfaceException("Error reading '" + scriptFileName + "' script.", e);
            }
            try {
                this.rConnection.voidEval(scriptString);
            }
            catch (RserveException e) {
                throw new RServeInterfaceException("Error running '" + scriptFileName + "' script.", e);
            }
        }
    }

    private void createRPositionFixDataFrame(List<PositionFix> positionFixList, String srs) throws RServeInterfaceException {
        int [] animalIds = new int[positionFixList.size()];
        double [] latitudes= new double[positionFixList.size()];
        double [] longitudes= new double[positionFixList.size()];

        /* load up the arrays from the database result set*/
        for (int i=0; i < positionFixList.size(); i++) {
            PositionFix positionFix = positionFixList.get(i);
            animalIds[i] = Integer.parseInt(positionFix.getAnimal().getId().toString());
            longitudes[i] = positionFix.getLocationGeometry().getX();
            latitudes[i] = positionFix.getLocationGeometry().getY();
        }

        /* create the RList to become the dataFrame (add the name+array) */
        RList rPositionFixList = new RList();
        rPositionFixList.put("Name", new REXPInteger(animalIds));
        rPositionFixList.put("X", new REXPDouble(longitudes));
        rPositionFixList.put("Y", new REXPDouble(latitudes));

        try {
            REXP rPosFixDataFrame = REXP.createDataFrame(rPositionFixList);
            this.rConnection.assign("positionFix", new REXPNull());
            this.rConnection.assign("positionFix", rPosFixDataFrame);

            // We use WGS84 for coordinates and project to a user-defined SRS.
            // We assume the user-supplied SRS has units of metres in our area calculations.
            safeEval("coordinates(positionFix) <- ~X+Y;");
            safeEval("positionFix.xy <- positionFix[, 'Name'];");
            safeEval("proj4string(positionFix.xy) <- CRS(\"+init=epsg:4326\");");
            safeEval("positionFix.proj <- try({spTransform(positionFix.xy,CRS(\"+init=" + srs + "\"))}, silent=TRUE);");
            safeEval(
                "if (class(positionFix.proj) == 'try-error') {\n" +
                "  stop(\"Unable to project locations. Please check that coordinates and the project's Spatial Reference System are valid.\")\n" +
                "}"
            );
        }
        catch (REngineException e) {
            throw new RServeInterfaceException(e.toString());
        }
        catch (REXPMismatchException e) {
            throw new RServeInterfaceException(e.toString());
        }
    }


    private void writeMCPKmlFile(Analysis analysis, String srs) throws RServeInterfaceException {
        AnalysisParameter percentParameter = analysis.getParamater("percent");
        Double percent = ((percentParameter != null) && (percentParameter.getValue() != null)) ? Double.valueOf(percentParameter.getValue()) : 100d;
        if (!(percent >= 0d && percent <= 100d)) {
            throw new RServeInterfaceException("percent must be between 0 and 100.");
        }
        safeEval("mcp.obj <- try({mcp(positionFix.xy, percent=" + percent + ")}, silent=TRUE)");
        safeEval(
            "if (class(mcp.obj) == 'try-error') {\n" +
            "  stop('At least 5 relocations are required to fit a home range. Please ensure all animals have >5 locations.')\n" +
            "}"
        );
        safeEval("mcp.obj$area <- mcp(positionFix.proj, percent=" + percent + ", unin=c(\"m\"), unout=c(\"km2\"))$area");
        safeEval("writeOGR(mcp.obj, dsn=\"" + analysis.getAbsoluteResultFilePath() + "\", layer= \"MCP\", driver=\"KML\", dataset_options=c(\"NameField=Name\"))");
    }

    private void writeKernelUDKmlFile(Analysis analysis, String srs) throws RServeInterfaceException {
        AnalysisParameter percentParameter = analysis.getParamater("percent");
        Double percent = ((percentParameter != null) && (percentParameter.getValue() != null)) ? Double.valueOf(percentParameter.getValue()) : 100d;
        if (!(percent >= 0d && percent <= 100d)) {
            throw new RServeInterfaceException("percent must be between 0 and 100.");
        }
        AnalysisParameterType hEstimatorParameterType = AnalysisType.KUD.getParameterType("hEstimator");
        AnalysisParameter hEstimatorParameter = analysis.getParamater(hEstimatorParameterType.getIdentifier());
        String hEstimator =
            ((hEstimatorParameter != null) && (hEstimatorParameter.getValue() != null) && hEstimatorParameterType.isValid(hEstimatorParameter.getValue()))
            ? hEstimatorParameter.getValue()
            : null;
        AnalysisParameterType hValueParameterType = AnalysisType.KUD.getParameterType("hValue");
        AnalysisParameter hValueParameter = analysis.getParamater(hValueParameterType.getIdentifier());
        Double hValue =
            ((hValueParameter != null) && (hValueParameter.getValue() != null) && hValueParameterType.isValid(hValueParameter.getValue()))
            ? Double.valueOf(hValueParameter.getValue())
            : null;
        if ((hEstimator == null) && (hValue == null)) {
            throw new RServeInterfaceException("h estimator or h value must be entered.");
        }
        String hExpr = (hValue != null) ? hValue.toString() : "\"" + hEstimator + "\"";
        AnalysisParameter gridSizeParameter = analysis.getParamater("gridSize");
        Double gridSize = ((gridSizeParameter != null) && (gridSizeParameter.getValue() != null)) ? Double.valueOf(gridSizeParameter.getValue()) : 50d;
        AnalysisParameter extentParameter = analysis.getParamater("extent");
        Double extent = ((extentParameter != null) && (extentParameter.getValue() != null)) ? Double.valueOf(extentParameter.getValue()) : 1d;
        safeEval("h <- " + hExpr);
        safeEval("KerHRp <- try({kernelUD(xy=positionFix.proj, h=h, grid=" + gridSize + ", extent=" + extent + ")}, silent=TRUE)");
        safeEval(
            "if (class(KerHRp) == 'try-error') {\n" +
            "  if (h == 'href') {\n" +
            "    stop('Kernel unable to generate under these parameters. Try increasing the extent.')\n" +
            "  }\n" +
            "  if (h == 'LSCV') {\n" +
            "    stop('Kernel unable to generate under these parameters. Try increasing the extent and the grid size.')\n" +
            "  }\n" +
            "  if (class(h) == 'numeric') {\n" +
            "    stop('Kernel unable to generate under these parameters. Try increasing the h smoothing parameter value.')\n" +
            "  }\n" +
            "  stop('Kernel unable to generate due to error: ' + conditionMessage(KerHRp))\n" +
            "}"
        );
        safeEval("allh <- sapply(1:length(KerHRp), function(x) {KerHRp[[x]]@h$h})");
        safeEval("myKerP <- try({getverticeshr(KerHRp, percent=" + percent + ", unin=c(\"m\"), unout=c(\"km2\"))}, silent=TRUE)");
        safeEval(
            "if (class(myKerP) == 'try-error') {\n" +
            "  stop('Kernel polygon unable to generate under these parameters. Try increasing the grid size or change the percentile.')\n" +
            "}"
        );
        safeEval("myKer <- spTransform(myKerP, CRS(\"+proj=longlat +datum=WGS84\"))");
        safeEval("myKer$area <- myKerP$area");
        safeEval("myKer$hval <- allh");
        safeEval("writeOGR(myKer, dsn=\"" + analysis.getAbsoluteResultFilePath() + "\", layer= \"KUD\", driver=\"KML\", dataset_options=c(\"NameField=Name\"))");
    }

    private void writeAlphahullKmlFile(Analysis analysis, String srs) throws RServeInterfaceException {
        AnalysisParameter alphaParameter = analysis.getParamater("alpha");
        Double alpha = ((alphaParameter != null) && (alphaParameter.getValue() != null)) ? Double.valueOf(alphaParameter.getValue()) : 0.1d;
        if (!(alpha > 0d)) {
            throw new RServeInterfaceException("alpha must be greater than 0.");
        }
        safeEval("myAhull <- myalphahullP(positionFix.proj, sinputssrs=\"+init=" + srs + "\", ialpha=" + alpha + ")");
        safeEval("writeOGR(myAhull, dsn=\"" + analysis.getAbsoluteResultFilePath() + "\", layer=\"AHULL\", driver=\"KML\", dataset_options=c(\"NameField=Name\"))");
    }

    private void writePointHeatmapKmlFile(Analysis analysis, String srs) throws RServeInterfaceException {
        AnalysisParameter gridSizeParameter = analysis.getParamater("gridSize");
        Double gridSize = ((gridSizeParameter != null) && (gridSizeParameter.getValue() != null)) ? Double.valueOf(gridSizeParameter.getValue()) : 100d;
        if (!(gridSize > 0d)) {
            throw new RServeInterfaceException("grid size must be greater than 0.");
        }
        AnalysisParameter showAbsenceParameter = analysis.getParamater("showAbsence");
        String labsent = ((showAbsenceParameter != null) && (showAbsenceParameter.getValue() != null) && Boolean.parseBoolean(showAbsenceParameter.getValue())) ? "TRUE" : "FALSE";
        AnalysisParameterType coloursParameterType = AnalysisType.HEATMAP_POINT.getParameterType("colours");
        AnalysisParameter coloursParameter = analysis.getParamater(coloursParameterType.getIdentifier());
        String scol = ((coloursParameter != null) && (coloursParameter.getValue() != null) && coloursParameterType.isValid(coloursParameter.getValue())) ? coloursParameter.getValue() : coloursParameterType.getDefaultValue();
        safeEval("PPA <- try({fpdens2kml(sdata=positionFix.xy, igrid=" + gridSize + ", ssrs=\"+init=" + srs + "\", scol=\"" + scol + "\", labsent=" + labsent + ")}, silent=TRUE)");
        safeEval(
            "if (class(PPA) == 'try-error') {\n" +
            "  stop('Grid size too small. Try increasing grid number.')\n" +
            "}"
        );
        safeEval("polykml(sw=PPA, filename=\"" + analysis.getAbsoluteResultFilePath() + "\", kmlname=paste(unique(PPA$ID), \"_point_density\",sep=\"\"),namefield=unique(PPA$ID))");
    }

    private void writeLineHeatmapKmlFile(Analysis analysis, String srs) throws RServeInterfaceException {
        AnalysisParameter gridSizeParameter = analysis.getParamater("gridSize");
        Double gridSize = ((gridSizeParameter != null) && (gridSizeParameter.getValue() != null)) ? Double.valueOf(gridSizeParameter.getValue()) : 100d;
        if (!(gridSize > 0d)) {
            throw new RServeInterfaceException("grid size must be greater than 0.");
        }
        AnalysisParameter showAbsenceParameter = analysis.getParamater("showAbsence");
        String labsent = ((showAbsenceParameter != null) && (showAbsenceParameter.getValue() != null) && Boolean.parseBoolean(showAbsenceParameter.getValue())) ? "TRUE" : "FALSE";
        AnalysisParameterType coloursParameterType = AnalysisType.HEATMAP_LINE.getParameterType("colours");
        AnalysisParameter coloursParameter = analysis.getParamater(coloursParameterType.getIdentifier());
        String scol = ((coloursParameter.getValue() != null) && coloursParameterType.isValid(coloursParameter.getValue())) ? coloursParameter.getValue() : coloursParameterType.getDefaultValue();
        safeEval("LPA <- try({fldens2kml(sdata=positionFix.xy, igrid=" + gridSize + ", ssrs=\"+init=" + srs + "\",scol=\"" + scol + "\", labsent=" + labsent + ")}, silent=TRUE)");
        safeEval(
            "if (class(LPA) == 'try-error') {\n" +
            "  stop('Grid size too small. Try increasing grid number.')\n" +
            "}"
        );
        safeEval("polykml(sw=LPA, filename=\"" + analysis.getAbsoluteResultFilePath() + "\", kmlname=paste(unique(LPA$ID), \"_line_density\", sep=\"\"), namefield=unique(LPA$ID))");
    }

    // Wraps an R statement inside a try({...}, silent=TRUE) so we can catch any exception
    // that occurs during evaluation. This gives us a much better error message, such as
    //
    //     Error in .kernelUDs(SpatialPoints(x, proj4string = CRS(as.character(pfs1))),  :
    //     h should be numeric or equal to either "href" or "LSCV"
    //
    // instead of just this if we catch exceptions from RConnection.voidEval(...)
    //
    //     org.rosuda.REngine.Rserve.RserveException: voidEval failed
    //
    private void safeEval(String rCommand) throws RServeInterfaceException {
        logger.debug(String.format("Evaluating R: %s", rCommand));
        try {
            rConnection.eval("e <- tryCatch({" + rCommand + "}, error = function(e) {e})");
        }
        catch (RserveException e) {
            throw new RServeInterfaceException("Error evaluating expression", e);
        }
        String errorMessage = null;
        try {
            if (rConnection.eval("inherits(e, 'error')").asInteger() == 1) {
                errorMessage = rConnection.eval("conditionMessage(e)").asString();
            }
        }
        catch (Exception e) {
            throw new RServeInterfaceException("Error getting error message", e);
        }
        if (errorMessage != null) {
            throw new RServeInterfaceException(errorMessage);
        }
    }
}