//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.Util {

    int compare_events (E.CalComponent comp1, E.CalComponent comp2) {

        var date1 = Util.ical_to_date_time (comp1.get_icalcomponent ().get_dtstart ());
        var date2 = Util.ical_to_date_time (comp2.get_icalcomponent ().get_dtstart ());

        if (date1.compare (date2) != 0)
            return date1.compare(date2);

        // If they have the same date, sort them alphabetically
        E.CalComponentText summary1;
        E.CalComponentText summary2;

        comp1.get_summary (out summary1);
        comp2.get_summary (out summary2);

        if (summary1.value < summary2.value)
            return -1;
        if (summary1.value > summary2.value)
            return 1;
        return 0;
    }

    //--- Date and Time ---//


    /**
     * Converts two datetimes to one icaltimetype. The first contains the date,
     * its time settings are ignored. The second one contains the time itself.
     */
    iCal.icaltimetype date_time_to_ical (DateTime date, DateTime time) {

        iCal.icaltimetype result = iCal.icaltime_from_day_of_year 
            (date.get_day_of_year (), date.get_year ());

        result.hour = time.get_hour ();
        result.minute = time.get_minute ();
        result.second = time.get_second ();

        return result;
    }

    /**
     * Converts the given icaltimetype to the given DateTime.
     */
    DateTime ical_to_date_time (iCal.icaltimetype date) {

        string tzid = date.zone.get_tzid ();
        TimeZone zone = new TimeZone (tzid);

        return new DateTime (zone, date.year, date.month,
            date.day, date.hour, date.minute, date.second);
    }

    /**
     * Say if an event last the all say.
     */
    bool is_the_all_day (DateTime dtstart, DateTime dtend) {
        if ((dtend.get_hour() == dtend.get_minute()) && (dtstart.get_hour() == dtend.get_hour()) && (dtstart.get_hour() == dtstart.get_minute()) && (dtend.get_hour() == 0)) {
            return true;
        }
        else {
            return false;
        }
    }

    public DateTime get_start_of_month (owned DateTime? date = null) {
        
        if (date==null)
            date = new DateTime.now_local();

        return new DateTime.local (date.get_year(), date.get_month(), 1, 0, 0, 0);
    }

    public DateTime strip_time (DateTime datetime) {
        int y,m,d;
        datetime.get_ymd (out y, out m, out d);
        return new DateTime.local (y, m, d, 0, 0, 0);
    }

    /* Create a map interleaving DateRanges dr1 and dr2 */
    public Gee.Map<DateTime, DateTime> zip_date_ranges (DateRange dr1, DateRange dr2)
        requires (dr1.days == dr2.days) {
        
        var map = new Gee.TreeMap<DateTime, DateTime>(
            (CompareFunc) DateTime.compare,
            (EqualFunc) datetime_equal_func);

        var i1 = dr1.iterator();
        var i2 = dr2.iterator();

        while (i1.next() && i2.next()) {
            map.set (i1.get(), i2.get());
        }

        return map;
    }

    /* Iterator of DateRange objects */
    public class DateIterator : Object, Gee.Iterator<DateTime> {

        DateTime current;
        DateRange range;

        public DateIterator (DateRange range) {
            this.range = range;
            this.current = range.first.add_days (-1);
        }

        public bool next () {
            if (! has_next ())
                return false;
            current = this.current.add_days (1);
            return true;
        }

        public bool has_next() {
            return current.compare(range.last) < 0;
        }

        public bool first () {
            current = range.first;
            return true;
        }

        public new DateTime get () {
            return current;
        }

        public void remove() {
            assert_not_reached();
        }
    }

    /* Represents date range from 'first' to 'last' inclusive */
    public class DateRange : Object, Gee.Iterable<DateTime> {

        public DateTime first { get; private set; }
        public DateTime last { get; private set; }

        public int64 days {
            get { return last.difference(first).DAY; }
        }

        public DateRange (DateTime first, DateTime last) {
            assert (first.compare(last)<=0);
            this.first = first;
            this.last = last;
        }

        public DateRange.copy (DateRange date_range) {
            this (date_range.first, date_range.last);
        }

        public bool equals (DateRange other) {
            return (first==other.first && last==other.last);
        }

        public Type element_type {
            get { return typeof(DateTime); }
        }

        public Gee.Iterator<DateTime> iterator () {
            return new DateIterator (this);
        }

        public bool contains (DateTime time) {
            return (first.compare (time) < 1) && (last.compare (time) > -1);
        }

        public Gee.SortedSet<DateTime> to_set() {

            var @set = new Gee.TreeSet<DateTime> ((CompareFunc) DateTime.compare);

            foreach (var date in this)
                set.add (date);

            return @set;
        }

        public Gee.List<DateTime> to_list() {

            var list = new Gee.ArrayList<DateTime> ((EqualFunc) datetime_equal_func);

            foreach (var date in this)
                list.add (date);

            return list;
        }
    }

    // /* Convert E.CalComponentDateTime to GLib.DateTime */
    // public DateTime convert_to_datetime (E.CalComponentDateTime dt) {
    // 
    //     unowned iCal.icaltimetype idt = dt.value;
    //     var tz = new TimeZone (dt.tzid);
    // 
    //     return new DateTime(tz, idt.year, idt.month, idt.day, idt.hour, idt.minute, idt.second);
    // }

    //--- Gee Utility Functions ---//

    /* Interleaves the values of two collections into a Map */
    public void zip<F, G> (Gee.Iterable<F> iterable1, Gee.Iterable<G> iterable2, ref Gee.Map<F, G> map) {

        var i1 = iterable1.iterator();
        var i2 = iterable2.iterator();

        while (i1.next() && i2.next())
            map.set (i1, i2);
    }

    /* Constructs a new set with keys equal to the values of keymap */
    public void remap<K, V> (Gee.Map<K, K> keymap, Gee.Map<K, V> valmap, ref Gee.Map<K, V> remap) {

        foreach (K key in valmap) {

            var k = keymap [key];
            var v = valmap [key];

            remap.set (k, v);
        }
    }

    /* Computes hash value for string */
    public uint string_hash_func (string key) {
        return key.hash();
    }

    /* Computes hash value for DateTime */
    public uint datetime_hash_func (DateTime key) {
        return key.hash();
    }

    /* Computes hash value for E.CalComponent */
    public uint calcomponent_hash_func (E.CalComponent key) {
        string uid;
        key.get_uid (out uid);
        return str_hash (uid);
    }

    /* Computes hash value for E.Source */
    public uint source_hash_func (E.Source key) {
        return str_hash (key.peek_uid());
    }

    /* Computes hash value for E.SourceGroup */
    public uint source_group_hash_func (E.SourceGroup key) {
        return str_hash (key.peek_uid());
    }

    /* Returns true if 'a' and 'b' are the same string */
    public bool string_equal_func (string a, string b) {
        return a == b;
    }

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    public bool datetime_equal_func (DateTime a, DateTime b) {
        return a.equal (b);
    }

    /* Returns true if 'a' and 'b' are the same E.SourceGroup */
    public bool source_group_equal_func (E.SourceGroup a, E.SourceGroup b) {
        return a.peek_uid() == b.peek_uid();
    }

    /* Returns true if 'a' and 'b' are the same E.CalComponent */
    public bool calcomponent_equal_func (E.CalComponent a, E.CalComponent b) {
        string uid_a, uid_b;
        a.get_uid (out uid_a);
        b.get_uid (out uid_b);
        return uid_a == uid_b;
    }

    /* Returns true if 'a' and 'b' are the same E.Source */
    public bool source_equal_func (E.Source a, E.Source b) {
        return a.peek_uid() == b.peek_uid();
    }

    //--- TreeModel Utility Functions ---//

    public Gtk.TreePath? find_treemodel_object<T> (Gtk.TreeModel model, int column, T object, EqualFunc<T>? eqfunc=null) {

        Gtk.TreePath? path = null;

        model.foreach( (m, p, iter) => {
            
            Value gvalue;
            model.get_value (iter, column, out gvalue);

            T ovalue = gvalue.get_object();

            if (   (eqfunc == null && ovalue == object)
                || (eqfunc != null && eqfunc(ovalue, object))) {
                path = p;
                return true;
            }

            return false;
        });

        return path;
    }

    //--- Gtk Miscellaneous ---//

    public class Css {

        private static Gtk.CssProvider? _css_provider;

        // Retrieve global css provider
        public static Gtk.CssProvider get_css_provider () {

            if (_css_provider == null) {
                _css_provider = new Gtk.CssProvider ();
                try {
                    _css_provider.load_from_path (Build.PKGDATADIR + "/style/default.css");
                } catch (Error e) {
                    warning ("Could not add css provider. Some widgets will not look as intended. %s", e.message);
                }
            }

            return _css_provider;
        }
    }

    public Gtk.Widget set_margins (Gtk.Widget widget, int top, int right, int bottom, int left) {
        
        widget.margin_top = top;
        widget.margin_right = right;
        widget.margin_bottom = bottom;
        widget.margin_left = left;
        
        return widget;
    }

    public Gtk.Alignment set_paddings (Gtk.Widget widget, int top, int right, int bottom, int left) {

        var alignment = new Gtk.Alignment (0.0f, 0.0f, 1.0f, 1.0f);
        alignment.top_padding = top;
        alignment.right_padding = right;
        alignment.bottom_padding = bottom;
        alignment.left_padding = left;

        alignment.add (widget);
        return alignment;
    }
    

    //--- ical Exportation ---//


    /**
     * Export all the selected calendars to a temporary ical file
     * TODO : The code can surely be optimised, it is just a first try.
     */

    public void save_temp_selected_calendars (){
        var sourcemagr = new Model.SourceManager ();
        var calmodel = new Model.CalendarModel(sourcemagr, Maya.Settings.Weekday.MONDAY);

        var path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
        string output = "";
        foreach (var source in sourcemagr.get_enabled_sources ()) {
            
            try {
                var client = new E.CalClient(source, E.CalClientSourceType.EVENTS);

                var iso_first = E.isodate_from_time_t((ulong) calmodel.data_range.first.to_unix());
                var iso_last = E.isodate_from_time_t((ulong) calmodel.data_range.last.to_unix());

                var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";
                GLib.SList<weak iCal.icalcomponent> icalcomps;
                client.get_object_list_sync(query, out icalcomps, null);

                foreach (var icalcomp in icalcomps) {
                    assert (icalcomp != null);

                    output = output + icalcomp.as_ical_string ();
                }
            } catch (GLib.Error e) {
                warning (e.message);
            }
            
        }
        try {
            GLib.FileUtils.set_contents (path, output);
        } catch (GLib.Error e){
            warning (e.message);
        }
    }

}
