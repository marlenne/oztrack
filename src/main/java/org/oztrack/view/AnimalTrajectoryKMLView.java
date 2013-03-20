package org.oztrack.view;

import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.oztrack.app.OzTrackConfiguration;
import org.oztrack.data.model.Animal;
import org.oztrack.data.model.PositionFix;
import org.springframework.web.servlet.view.AbstractView;

public class AnimalTrajectoryKMLView extends AbstractView{
    private final SimpleDateFormat isoDateTimeFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

    private final OzTrackConfiguration configuration;
    private final Animal animal;
    private final Date fromDate;
    private final Date toDate;
    private final List<PositionFix> positionFixList;

    public AnimalTrajectoryKMLView(
        OzTrackConfiguration configuration,
        Animal animal,
        Date fromDate,
        Date toDate,
        List<PositionFix> positionFixList
    ) {
        this.configuration = configuration;
        this.animal = animal;
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.positionFixList = positionFixList;
    }

    @Override
    protected void renderMergedOutputModel(
        @SuppressWarnings("rawtypes") Map model,
        HttpServletRequest request,
        HttpServletResponse response
    ) throws Exception {
        String fileName = "trajectory-" + animal.getId() + ".kml";
        response.setHeader("Content-Disposition", "attachment; filename=\""+ fileName + "\"");
        response.setContentType("application/xml");
        response.setCharacterEncoding("UTF-8");

        PrintWriter writer = response.getWriter();
        writer.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        writer.append("<kml xmlns=\"http://earth.google.com/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\">\n");
        writer.append("<Document>\n");
        writer.append("  <description>\n");
        writer.append("    <p>\n");
        writer.append("      Trajectory for animal " + animal.getId() + ",\n");
        writer.append("      " + dateFormat.format(fromDate) + " - " + dateFormat.format(toDate) + ".\n");
        writer.append("    </p>\n");
        writer.append("    <p>Generated by OzTrack\n" + (configuration.getBaseUrl() + "/") + "</p>\n");
        writer.append("  </description>\n");
        Matcher m = Pattern.compile("^#(..)(..)(..)$").matcher(animal.getColour());
        String kmlBaseColour = m.matches() ? (m.group(3) + m.group(2) + m.group(1)) : "40c4ff";
        String kmlIconColour = "cc" + kmlBaseColour; // 80% opacity
        writer.append("<Placemark>\n");
        writer.append("<name>" + animal.getId() + "</name>\n");
        writer.append("<StyleMap>\n");
        writer.append("<Pair>\n");
        writer.append("  <key>normal</key>\n");
        writer.append("  <Style>\n");
        writer.append("    <IconStyle>\n");
        writer.append("      <color>ff40c4ff</color>\n");
        writer.append("      <scale>1</scale>\n");
        writer.append("      <Icon>\n");
        writer.append("        <href>http://maps.google.com/mapfiles/kml/shapes/track.png</href>\n");
        writer.append("      </Icon>\n");
        writer.append("    </IconStyle>\n");
        writer.append("    <LineStyle>\n");
        writer.append("      <color>" + kmlIconColour + "</color>\n");
        writer.append("      <width>3</width>\n");
        writer.append("    </LineStyle>\n");
        writer.append("  </Style>\n");
        writer.append("</Pair>\n");
        writer.append("<Pair>\n");
        writer.append("  <key>highlight</key>\n");
        writer.append("  <Style>\n");
        writer.append("    <IconStyle>\n");
        writer.append("      <color>ff40c4ff</color>\n");
        writer.append("      <scale>1.33</scale>\n");
        writer.append("      <Icon>\n");
        writer.append("        <href>http://maps.google.com/mapfiles/kml/shapes/track.png</href>\n");
        writer.append("      </Icon>\n");
        writer.append("    </IconStyle>\n");
        writer.append("    <LineStyle>\n");
        writer.append("      <color>ff40c4ff</color>\n");
        writer.append("      <width>4</width>\n");
        writer.append("    </LineStyle>\n");
        writer.append("  </Style>\n");
        writer.append("</Pair>\n");
        writer.append("</StyleMap>\n");
        writer.append("<gx:Track>\n");
        for(PositionFix positionFix : positionFixList) {
            writer.append("  <when>" + isoDateTimeFormat.format(positionFix.getDetectionTime()) + "</when>\n");
            writer.append("  <gx:coord>" + positionFix.getLocationGeometry().getX() + " " + positionFix.getLocationGeometry().getY() + " 0</gx:coord>\n");
        }
        writer.append("</gx:Track>\n");
        writer.append("</Placemark>\n");
        writer.append("</Document>\n");
        writer.append("</kml>");
    }
}