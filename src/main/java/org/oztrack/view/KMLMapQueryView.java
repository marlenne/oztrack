package org.oztrack.view;

import java.io.File;
import java.io.FileInputStream;
import java.util.Locale;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.oztrack.data.access.PositionFixDao;
import org.oztrack.data.model.SearchQuery;
import org.oztrack.util.RServeInterface;
import org.springframework.web.servlet.view.AbstractView;

public class KMLMapQueryView extends AbstractView {
    // TODO: DAO should not appear in this layer.
    private PositionFixDao positionFixDao;
    
    public KMLMapQueryView(PositionFixDao positionFixDao) {
        this.positionFixDao = positionFixDao;
    }
    
    @Override
    protected void renderMergedOutputModel(
        @SuppressWarnings("rawtypes") Map model,
        HttpServletRequest request,
        HttpServletResponse response
    ) throws Exception {
        SearchQuery searchQuery = (SearchQuery) model.get("searchQuery");
        if (searchQuery.getProject() == null) {
            return;
        }

        RServeInterface rServeInterface = new RServeInterface(searchQuery, positionFixDao);
        File kmlFile = rServeInterface.createKml();

        FileInputStream fin = new FileInputStream(kmlFile);
        byte kmlContent[] = new byte[(int) kmlFile.length()];
        fin.read(kmlContent);

        String filename = searchQuery.getMapQueryType().name().toLowerCase(Locale.ENGLISH) + ".kml";
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/xml");
        response.getOutputStream().write(kmlContent);
        kmlFile.delete();
    }
}