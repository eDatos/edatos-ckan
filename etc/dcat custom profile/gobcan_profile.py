from datetime import datetime
from rdflib.namespace import Namespace, XSD, RDF, RDFS
from ckanext.dcat.profiles import RDFProfile
from ckan.model.license import LicenseRegister
from rdflib import Literal, URIRef, BNode
from ckantoolkit import config

DCT = Namespace("http://purl.org/dc/terms/")
DCAT = Namespace("http://www.w3.org/ns/dcat#")
TIME = Namespace("http://www.w3.org/2006/time#")


class GobCanProfile(RDFProfile):
    '''
    An RDF profile for the GOBCAN DCAT-AP opendata portal

    It requires the European DCAT-AP profile (`euro_dcat_ap`)
    '''

    def _license_new(self, dataset_ref):
        '''
        Returns the dataset license identifier if is found. If no dataset's
        license matches, retuns one of the distributions license is found in
        CKAN license registry. If no distribution's license matches, an empty
        string is returned.

        The first distribution with a license found in the registry is used so
        that if distributions have different licenses we'll only get the first
        one.
        '''
        if self._licenceregister_cache is not None:
            license_uri2id, license_title2id = self._licenceregister_cache
        else:
            license_uri2id = {}
            license_title2id = {}
            for license_id, license in LicenseRegister().items():
                license_uri2id[license.url] = license_id
                license_title2id[license.title] = license_id
            self._licenceregister_cache = license_uri2id, license_title2id

        dataset_license = self._object(dataset_ref, DCT.license)
        if dataset_license:
            license_id = license_uri2id.get(dataset_license.toPython())
            if not license_id:
                license_id = license_title2id.get(
                    self._object_value(dataset_license, DCT.title))
            if license_id:
                return license_id
        else:
            for distribution in self._distributions(dataset_ref):
                # If distribution has a license, attach it to the dataset
                license = self._object(distribution, DCT.license)
                if license:
                    # Try to find a matching license comparing URIs, then titles
                    license_id = license_uri2id.get(license.toPython())
                    if not license_id:
                        license_id = license_title2id.get(
                            self._object_value(license, DCT.title))
                    if license_id:
                        return license_id
            return ''

    def _check_time_tag(self, value):
        '''
        Returns a string with the update frequency checking the time
        tag
        '''
        years = self._object_value(value[0], TIME.years)
        if years:
            return 'Anual'

        months = self._object_value(value[0], TIME.months)
        if months:
            if months == '6':
                return 'Semestral'
            if months == '3':
                return 'Trimestral'
            if months == '2':
                return 'Bimensual'
            if months == '1':
                return 'Mensual'

        days = self._object_value(value[0], TIME.days)
        if days:
            if days == '15':
                return 'Quincenal'
            if days == '7':
                return 'Semanal'
            if days == '1':
                return 'Diaria'

    def _frequency(self, subject, predicate):
        '''
        Returns a string with the frequency about a dct:accrualPeriodicity entity

        Both subject and predicate must be rdflib URIRef or BNode objects

        Checks if Value has the label tag, otherwise it would check the time tag

        Example:

        <dct:accrualPeriodicity>
            <dct:Frequency>
            <rdfs:label>Cada @@intervalo-tiempo@@</rdfs:label>
            <rdf:value>
                <time:DurationDescription>
                    <rdfs:label>@@intervalo-tiempo@@</rdfs:label>
                    <!-- puede ser time:days o otra magnitud (weeks, months, etc.) -->
                    <time:days rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">@@n@@</time:days>
                </time:DurationDescription>
            </rdf:value>
            </dct:Frequency>
        </dct:accrualPeriodicity>

        Returns a string with the frequency value set to an empty string if
        it could not be found
        '''

        value = frec = None

        for frequency in self.g.objects(subject, predicate):
            value = [t for t in self.g.objects(frequency, RDF.value)]
            if value:
                frec = self._object_value(value[0], RDFS.label)
                if frec.lower() in ('anual',
                                    'semestral',
                                    'trimestral',
                                    'bimensual',
                                    'mensual',
                                    'quincenal',
                                    'semanal',
                                    'diaria'):
                    return frec
                else:
                    return self._check_time_tag(value)

    def _get_frequency_details(self, frequency):
        '''
        Returns the time tag, the update frequency string and integer
        '''
        frequencies = {
            'anual': (TIME.years, 'Anual', 1),
            'semestral': (TIME.months, 'Semestral', 6),
            'trimestral': (TIME.months, 'Trimestral', 3),
            'bimensual': (TIME.months, 'Bimensual', 2),
            'mensual': (TIME.months, 'Mensual', 1),
            'quincenal': (TIME.days, 'Quincenal', 15),
            'semanal': (TIME.days, 'Semanal', 7),
            'diaria': (TIME.days, 'Diaria', 1),
        }
        return frequencies.get(frequency.lower(), (TIME.years, 'Anual', '0'))

    def parse_dataset(self, dataset_dict, dataset_ref):
        # License
        if 'license_id' not in dataset_dict:
            dataset_dict['license_id'] = self._license_new(dataset_ref)

        # Frequency
        frequency = self._frequency(dataset_ref, DCT.accrualPeriodicity)
        if frequency:
            for item in dataset_dict['extras']:
                if item['key'] == 'frequency':
                    item['value'] = frequency

        return dataset_dict

    def graph_from_dataset(self, dataset_dict, dataset_ref):
        g = self.g

        # Add the namespace time to vocabulary
        g.bind('time', TIME)

        # License
        license_id = self._get_dataset_value(dataset_dict, 'license_url')
        if license_id:
            g.add((dataset_ref, DCT.license, Literal(license_id)))

        # Frequency
        frequency = self._get_dataset_value(dataset_dict, 'frequency')
        if frequency is not None:
            label, frec, times = self._get_frequency_details(frequency)
            frequency_node = BNode()
            duration_desc_node = BNode()

            # Remove EuropeanDCATProfile accrualPeriodicity node
            g.remove((dataset_ref, DCT.accrualPeriodicity, None))

            # AccrualPeriodicity
            g.add((dataset_ref, DCT.accrualPeriodicity, frequency_node))

            # Frequency
            g.add((frequency_node, RDF.type, DCT.Frequency))

            # Value -> DurationDescription -> Label and Time:X
            g.add((frequency_node, RDF.value, duration_desc_node))
            g.add((duration_desc_node, RDF.type,  TIME.DurationDescription))
            g.add((duration_desc_node, RDFS.label, Literal(frec)))
            g.add((duration_desc_node, label, Literal(times)))

    def graph_from_catalog(self, catalog_dict, catalog_ref):
        g = self.g

        items = [
            ('themeTaxonomy', DCAT.themeTaxonomy,
             config.get('ckan.theme_taxonomy'), URIRef),
            ('publisher', DCT.publisher, config.get('ckan.publisher'), URIRef),
            ('license', DCT.license, config.get('ckan.license'), URIRef),
        ]
        for item in items:
            key, predicate, fallback, _type = item
            if catalog_dict:
                value = catalog_dict.get(key, fallback)
            else:
                value = fallback
            if value:
                g.add((catalog_ref, predicate, _type(value)))

        date = datetime.now()
        self._add_date_triple(catalog_ref, DCT.issued, Literal(date.isoformat(),
                                                               datatype=XSD.dateTime))

