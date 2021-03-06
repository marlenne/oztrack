package org.oztrack.data.model;

import java.util.Date;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.DiscriminatorColumn;
import javax.persistence.DiscriminatorType;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Inheritance;
import javax.persistence.InheritanceType;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.persistence.UniqueConstraint;

import org.oztrack.data.model.types.AnalysisResultAttributeType;

@Entity
@Inheritance(strategy=InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name="resulttype", discriminatorType=DiscriminatorType.STRING)
@Table(name="analysis_result_feature", uniqueConstraints=@UniqueConstraint(columnNames={"analysis_id", "animal_id"}))
public abstract class AnalysisResultFeature {
    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="analysis_result_feature_id_seq")
    @SequenceGenerator(name="analysis_result_feature_id_seq", sequenceName="analysis_result_feature_id_seq", allocationSize=1)
    @Column(nullable=false)
    private Long id;

    @ManyToOne
    @JoinColumn(name="analysis_id", nullable=false)
    private Analysis analysis;

    @ManyToOne
    @JoinColumn(name="animal_id", nullable=false)
    private Animal animal;
    
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name="datetime", nullable=true)
    private Date dateTime;

    @OneToMany(mappedBy="feature", cascade=CascadeType.ALL, orphanRemoval=true, fetch=FetchType.EAGER)
    private Set<AnalysisResultAttribute> attributes;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Analysis getAnalysis() {
        return analysis;
    }

    public void setAnalysis(Analysis analysis) {
        this.analysis = analysis;
    }

    public Animal getAnimal() {
        return animal;
    }

    public void setAnimal(Animal animal) {
        this.animal = animal;
    }

    public Date getDateTime() {
        return dateTime;
    }

    public void setDateTime(Date dateTime) {
        this.dateTime = dateTime;
    }

    public Set<AnalysisResultAttribute> getAttributes() {
        return attributes;
    }

    public void setAttributes(Set<AnalysisResultAttribute> attributes) {
        this.attributes = attributes;
    }

    public AnalysisResultAttribute getAttribute(String name) {
        for (AnalysisResultAttribute attribute : attributes) {
            if (attribute.getName().equals(name)) {
                return attribute;
            }
        }
        return null;
    }

    public Object getAttributeValue(String name) {
        AnalysisResultAttributeType attributeType = analysis.getAnalysisType().getFeatureResultAttributeType(name);
        AnalysisResultAttribute resultAttribute = getAttribute(attributeType.getIdentifier());
        if (resultAttribute == null) {
            return null;
        }
        return attributeType.getAttributeValueObject(resultAttribute.getValue());
    }
}
